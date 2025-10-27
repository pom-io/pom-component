# frozen_string_literal: true

require "test_helper"

module Pom
  class OptionDslTest < ActiveSupport::TestCase
    # Test class that includes OptionDsl
    class BasicComponent
      include Pom::OptionDsl

      option :name
      option :size, default: :md
      option :variant, enums: [:solid, :outline, :ghost]

      def initialize(**kwargs)
        initialize_options(**kwargs)
      end
    end

    class RequiredComponent
      include Pom::OptionDsl

      option :title, required: true
      option :description
      option :status, required: true, default: :active

      def initialize(**kwargs)
        initialize_options(**kwargs)
      end
    end

    class EnumComponent
      include Pom::OptionDsl

      option :size, enums: [:sm, :md, :lg], default: :md
      option :color, enums: [:red, :blue, :green]

      def initialize(**kwargs)
        initialize_options(**kwargs)
      end
    end

    class InheritedComponent < BasicComponent
      option :color, enums: [:red, :blue, :green], default: :blue
      option :disabled, default: false
    end

    # Tests for basic option definition and access
    test "defines getter method for option" do
      component = BasicComponent.new(name: "test")
      assert_equal "test", component.name
    end

    test "defines setter method for option" do
      component = BasicComponent.new
      component.name = "updated"
      assert_equal "updated", component.name
    end

    test "defines predicate method for option" do
      component = BasicComponent.new(name: "test")
      assert component.name?

      component.name = nil
      assert_not component.name?
    end

    test "returns nil for unset option without default" do
      component = BasicComponent.new
      assert_nil component.name
    end

    test "uses default value when option not provided" do
      component = BasicComponent.new
      assert_equal :md, component.size
    end

    test "overrides default value when option provided" do
      component = BasicComponent.new(size: :lg)
      assert_equal :lg, component.size
    end

    # Tests for enum validation
    test "accepts valid enum value" do
      component = EnumComponent.new(size: :lg)
      assert_equal :lg, component.size
    end

    test "accepts valid enum value as string" do
      component = EnumComponent.new(size: "sm")
      assert_equal :sm, component.size
    end

    test "raises error for invalid enum value" do
      error = assert_raises(ArgumentError) do
        EnumComponent.new(size: :xl)
      end
      assert_match(/Invalid value for size: xl/, error.message)
      assert_match(/Must be one of sm, md, lg/, error.message)
    end

    test "allows nil for enum option without default" do
      component = EnumComponent.new(color: nil)
      assert_nil component.color
    end

    test "setter validates enum values" do
      component = EnumComponent.new
      component.size = :sm
      assert_equal :sm, component.size

      error = assert_raises(ArgumentError) do
        component.size = :invalid
      end
      assert_match(/Invalid value for size/, error.message)
    end

    # Tests for required options
    test "raises error when required option is missing" do
      error = assert_raises(ArgumentError) do
        RequiredComponent.new(description: "test")
      end
      assert_match(/Missing required option: title/, error.message)
    end

    test "accepts required option when provided" do
      component = RequiredComponent.new(title: "Test Title")
      assert_equal "Test Title", component.title
    end

    test "does not raise error for required option with default" do
      component = RequiredComponent.new(title: "Test")
      assert_equal :active, component.status
    end

    test "can override required option with default" do
      component = RequiredComponent.new(title: "Test", status: :inactive)
      assert_equal :inactive, component.status
    end

    # Tests for extra_options
    test "captures undefined options in extra_options" do
      component = BasicComponent.new(name: "test", custom_attr: "value", another: 123)
      assert_equal "value", component.extra_options[:custom_attr]
      assert_equal 123, component.extra_options[:another]
    end

    test "does not include defined options in extra_options" do
      component = BasicComponent.new(name: "test", size: :lg)
      assert_not component.extra_options.key?(:name)
      assert_not component.extra_options.key?(:size)
    end

    test "extra_options is empty when no extra options provided" do
      component = BasicComponent.new(name: "test")
      assert_empty component.extra_options
    end

    # Tests for class methods
    test "enum_values_for returns enum array" do
      assert_equal [:sm, :md, :lg], EnumComponent.enum_values_for(:size)
    end

    test "enum_values_for returns nil for non-enum option" do
      assert_nil BasicComponent.enum_values_for(:name)
    end

    test "default_value_for returns default value" do
      assert_equal :md, BasicComponent.default_value_for(:size)
    end

    test "default_value_for returns nil for option without default" do
      assert_nil BasicComponent.default_value_for(:name)
    end

    test "required_options returns array of required option names" do
      required = RequiredComponent.required_options
      assert_includes required, :title
      assert_not_includes required, :status # has default
      assert_not_includes required, :description # not required
    end

    test "optional_options returns array of optional option names" do
      optional = RequiredComponent.optional_options
      assert_includes optional, :description
      assert_includes optional, :status # has default
      assert_not_includes optional, :title # required without default
    end

    # Tests for instance methods
    test "option_values returns hash of all option values" do
      component = BasicComponent.new(name: "test", size: :sm)
      values = component.option_values

      assert_equal "test", values[:name]
      assert_equal :sm, values[:size]
      assert_nil values[:variant]
    end

    test "option_set? returns true when option explicitly set" do
      component = BasicComponent.new(name: "test")
      assert component.option_set?(:name)
    end

    test "option_set? returns false when option not set" do
      component = BasicComponent.new
      assert_not component.option_set?(:name)
    end

    test "option_set? returns true for default value set during initialization" do
      component = BasicComponent.new
      # Default values are set via the setter during initialization, so option_set? returns true
      assert component.option_set?(:size)
    end

    test "option_set? returns true when default value explicitly set" do
      component = BasicComponent.new(size: :md)
      assert component.option_set?(:size)
    end

    test "reset_option removes instance variable" do
      component = BasicComponent.new(name: "test")
      assert_equal "test", component.name

      component.reset_option(:name)
      assert_nil component.name
    end

    test "reset_option restores default value" do
      component = BasicComponent.new(size: :lg)
      assert_equal :lg, component.size

      component.reset_option(:size)
      assert_equal :md, component.size
    end

    test "reset_option handles non-existent option gracefully" do
      component = BasicComponent.new
      assert_nothing_raised do
        component.reset_option(:non_existent)
      end
    end

    # Tests for inheritance
    test "inherits parent options" do
      component = InheritedComponent.new(name: "test", color: :red)
      assert_equal "test", component.name
      assert_equal :red, component.color
    end

    test "inherited component has parent and own options" do
      options = InheritedComponent.options
      assert_includes options.keys, :name
      assert_includes options.keys, :size
      assert_includes options.keys, :color
      assert_includes options.keys, :disabled
    end

    test "child default does not affect parent" do
      assert_equal :md, BasicComponent.default_value_for(:size)
      assert_equal :blue, InheritedComponent.default_value_for(:color)
    end

    test "parent and child have separate option configurations" do
      parent_opts = BasicComponent.options
      child_opts = InheritedComponent.options

      assert_not_equal parent_opts.object_id, child_opts.object_id
    end

    # Tests for string keys in kwargs
    test "accepts string keys in initialization" do
      component = BasicComponent.new("name" => "test", "size" => :lg)
      assert_equal "test", component.name
      assert_equal :lg, component.size
    end

    test "string keys work with extra_options" do
      component = BasicComponent.new("name" => "test", "custom" => "value")
      assert_equal "value", component.extra_options[:custom]
    end

    # Edge cases
    test "handles nil option value" do
      component = BasicComponent.new(name: nil)
      assert_nil component.name
      assert_not component.name?
    end

    test "handles false as option value" do
      component = InheritedComponent.new(name: "test", disabled: false)
      assert_equal false, component.disabled
    end

    test "handles empty string as option value" do
      component = BasicComponent.new(name: "")
      assert_equal "", component.name
      assert_not component.name? # empty string is not present
    end

    test "option predicate returns false for false value" do
      component = InheritedComponent.new(name: "test", disabled: false)
      assert_not component.disabled?
    end

    test "option predicate returns true for truthy value" do
      component = InheritedComponent.new(name: "test", disabled: true)
      assert component.disabled?
    end

    test "supports symbols and strings for enum values" do
      component = EnumComponent.new(size: "lg")
      assert_equal :lg, component.size

      component.size = "sm"
      assert_equal :sm, component.size
    end

    # Tests for NO_DEFAULT sentinel
    test "distinguishes between nil and no default" do
      component = BasicComponent.new
      # name has no default, should return nil
      assert_nil component.name
      # size has default :md
      assert_equal :md, component.size
    end

    test "setting option to nil still returns default value from getter" do
      component = BasicComponent.new(size: nil)
      # When nil is set, the getter still returns the default value
      # because the getter checks if instance var is nil and returns default
      assert_equal :md, component.size
    end
  end
end
