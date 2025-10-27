# frozen_string_literal: true

require "test_helper"

module Pom
  class StyleableTest < ViewComponent::TestCase
    # Test component classes extending Pom::Component
    class BaseComponent < Pom::Component
      option :variant, enums: [:solid, :outline, :ghost], default: :solid
      option :size, enums: [:sm, :md, :lg], default: :md

      define_styles(
        base: "btn",
        variant: {
          solid: "bg-blue-500 text-white",
          outline: "border border-blue-500 text-blue-500",
          ghost: "text-blue-500",
        },
        size: {
          sm: "text-sm px-2 py-1",
          md: "text-base px-4 py-2",
          lg: "text-lg px-6 py-3",
        },
      )
    end

    class ExtendedComponent < BaseComponent
      # Re-define variant to add :link to the enum
      option :variant, enums: [:solid, :outline, :ghost, :link], default: :solid
      option :color, enums: [:red, :blue, :green], default: :blue

      define_styles(
        variant: {
          link: "underline text-blue-600",
        },
        color: {
          red: "text-red-500",
          blue: "text-blue-500",
          green: "text-green-500",
        },
      )
    end

    class HashBaseComponent < Pom::Component
      option :variant, enums: [:solid, :outline], default: :solid

      define_styles(
        base: {
          default: "btn rounded",
          hover: "hover:opacity-80",
          pressed: "active:scale-95",
        },
        variant: {
          solid: "bg-indigo-500",
          outline: "border border-indigo-500",
        },
      )
    end

    class LambdaComponent < Pom::Component
      option :variant, enums: [:solid, :outline], default: :solid
      option :color, default: "blue"
      option :disabled, default: false

      define_styles(
        base: "component",
        variant: {
          solid: ->(color: nil, disabled: false, **_opts) {
            classes = ["bg-#{color || "blue"}-500"]
            classes << "opacity-50" if disabled
            classes.join(" ")
          },
          outline: ->(color: nil, **_opts) { "border border-#{color || "blue"}-500" },
        },
      )
    end

    class GroupedComponent < Pom::Component
      option :size, enums: [:sm, :md, :lg], default: :md

      define_styles(:root, base: "container mx-auto")
      define_styles(:header, base: "text-2xl font-bold")
      define_styles(:footer, base: "text-sm text-gray-500")
      define_styles(
        :content,
        base: "p-6",
        size: {
          sm: "max-w-sm",
          md: "max-w-md",
          lg: "max-w-lg",
        },
      )
    end

    class BooleanStyleKeyComponent < Pom::Component
      option :disabled, default: false
      option :variant, enums: [:solid, :outline], default: :solid

      define_styles(
        base: "btn font-medium",
        disabled: {
          true: "opacity-50 cursor-not-allowed pointer-events-none",
          false: "cursor-pointer hover:opacity-80",
        },
        variant: {
          solid: "bg-blue-500 text-white",
          outline: "border border-blue-500 text-blue-500",
        },
      )
    end

    class LambdaBaseComponent < Pom::Component
      option :variant, enums: [:solid, :outline], default: :solid
      option :color, default: "blue"
      option :disabled, default: false

      define_styles(
        base: ->(color: nil, disabled: false, **_opts) {
          classes = ["component rounded"]
          classes << "bg-#{color || "blue"}-100"
          classes << "opacity-50 cursor-not-allowed" if disabled
          classes.join(" ")
        },
        variant: {
          solid: "font-bold shadow-md",
          outline: "border-2",
        },
      )
    end

    # Tests for basic functionality
    test "defines styles with default group" do
      component = BaseComponent.new(variant: :solid)
      styles = component.styles_for(variant: component.variant)

      assert_includes styles, "btn"
      assert_includes styles, "bg-blue-500"
      assert_includes styles, "text-white"
    end

    test "composes multiple style keys" do
      component = BaseComponent.new(variant: :solid, size: :lg)
      styles = component.styles_for(variant: component.variant, size: component.size)

      assert_includes styles, "btn"
      assert_includes styles, "bg-blue-500"
      assert_includes styles, "text-lg"
      assert_includes styles, "px-6"
      assert_includes styles, "py-3"
    end

    test "handles missing style keys gracefully" do
      component = BaseComponent.new(variant: :solid)
      styles = component.styles_for(variant: component.variant)

      # Should not include size classes when size is not specified
      refute_includes styles, "px-2"
      refute_includes styles, "px-6"
    end

    test "handles string variant values" do
      component = BaseComponent.new(variant: "outline")
      styles = component.styles_for(variant: component.variant)

      assert_includes styles, "border"
      assert_includes styles, "border-blue-500"
    end

    test "uses default option values" do
      component = BaseComponent.new
      styles = component.styles_for(variant: component.variant, size: component.size)

      # Should use default variant: :solid and size: :md
      assert_includes styles, "bg-blue-500"
      assert_includes styles, "px-4"
    end

    # Tests for hash base styles
    test "resolves hash base styles to all sub-values" do
      component = HashBaseComponent.new(variant: :solid)
      styles = component.styles_for(variant: component.variant)

      assert_includes styles, "btn"
      assert_includes styles, "rounded"
      assert_includes styles, "hover:opacity-80"
      assert_includes styles, "active:scale-95"
      assert_includes styles, "bg-indigo-500"
    end

    # Tests for lambda styles
    test "resolves lambda style values with params" do
      component = LambdaComponent.new(variant: :solid, color: "red")
      styles = component.styles_for(variant: component.variant, color: component.color, disabled: component.disabled)

      assert_includes styles, "component"
      assert_includes styles, "bg-red-500"
    end

    test "lambda receives extra params for custom logic" do
      component = LambdaComponent.new(variant: :solid, color: "green", disabled: true)
      styles = component.styles_for(variant: component.variant, color: component.color, disabled: component.disabled)

      assert_includes styles, "bg-green-500"
      assert_includes styles, "opacity-50"
    end

    test "lambda uses default values when params not provided" do
      component = LambdaComponent.new(variant: :solid)
      styles = component.styles_for(variant: component.variant, color: component.color, disabled: component.disabled)

      assert_includes styles, "bg-blue-500"
    end

    test "lambda in outline variant" do
      component = LambdaComponent.new(variant: :outline, color: "purple")
      styles = component.styles_for(variant: component.variant, color: component.color)

      assert_includes styles, "border"
      assert_includes styles, "border-purple-500"
    end

    # Tests for inheritance
    test "inherits parent component styles" do
      component = ExtendedComponent.new(variant: :solid, size: :md)
      styles = component.styles_for(variant: component.variant, size: component.size)

      # Inherited from BaseComponent
      assert_includes styles, "btn"
      assert_includes styles, "bg-blue-500"
      assert_includes styles, "px-4"
    end

    test "extends parent component with new style keys" do
      component = ExtendedComponent.new(variant: :solid, color: :red)
      styles = component.styles_for(variant: component.variant, color: component.color)

      assert_includes styles, "btn"
      assert_includes styles, "bg-blue-500"
      assert_includes styles, "text-red-500"
    end

    test "extends parent component with new variant values" do
      component = ExtendedComponent.new(variant: :link)
      styles = component.styles_for(variant: component.variant)

      assert_includes styles, "btn"
      assert_includes styles, "underline"
      assert_includes styles, "text-blue-600"
    end

    test "inherits parent options and adds new ones" do
      component = ExtendedComponent.new(variant: :solid, size: :lg, color: :green)

      # Should have parent options
      assert_equal :solid, component.variant
      assert_equal :lg, component.size
      # Should have new option
      assert_equal :green, component.color
    end

    # Tests for grouped styles
    test "supports custom style groups" do
      component = GroupedComponent.new(size: :lg)

      root_styles = component.styles_for(:root)
      assert_includes root_styles, "container"
      assert_includes root_styles, "mx-auto"

      header_styles = component.styles_for(:header)
      assert_includes header_styles, "text-2xl"
      assert_includes header_styles, "font-bold"

      footer_styles = component.styles_for(:footer)
      assert_includes footer_styles, "text-sm"
      assert_includes footer_styles, "text-gray-500"

      content_styles = component.styles_for(:content, size: component.size)
      assert_includes content_styles, "p-6"
      assert_includes content_styles, "max-w-lg"
    end

    test "returns empty string for undefined group" do
      component = GroupedComponent.new
      styles = component.styles_for(:undefined_group)

      assert_equal "", styles
    end

    # Tests for component integration
    test "component has access to all helper modules" do
      component = BaseComponent.new

      # Should include Styleable
      assert_respond_to component, :styles_for
      # Should include OptionHelper
      assert_respond_to component, :merge_options
      # Should include ViewHelper
      assert_respond_to component, :component_name
      # Should have component_name from Pom::Component
      assert_equal "base", component.component_name
    end

    test "extra_options are captured from OptionDsl" do
      component = BaseComponent.new(variant: :solid, custom_data: "test", aria_label: "button")

      assert_equal({ custom_data: "test", aria_label: "button" }, component.extra_options)
    end

    # Edge cases
    test "handles empty styles definition" do
      class EmptyComponent < Pom::Component
      end

      component = EmptyComponent.new
      styles = component.styles_for

      assert_equal "", styles
    end

    test "handles nil values gracefully" do
      component = BaseComponent.new(variant: :solid)
      styles = component.styles_for(variant: nil)

      # Should still include base
      assert_includes styles, "btn"
      # But not include any variant
      refute_includes styles, "bg-blue-500"
    end

    test "base only without any style keys" do
      component = BaseComponent.new
      styles = component.styles_for

      assert_equal "btn", styles
    end

    # TailwindMerge conflict resolution tests
    test "TailwindMerge resolves conflicting padding classes" do
      class ConflictPaddingComponent < Pom::Component
        option :variant, enums: [:normal, :large], default: :normal

        define_styles(
          base: "p-4",
          variant: {
            large: "p-8",
          },
        )
      end

      component = ConflictPaddingComponent.new(variant: :large)
      styles = component.styles_for(variant: component.variant)

      # TailwindMerge should keep only p-8, not both p-4 and p-8
      refute_includes styles, "p-4"
      assert_includes styles, "p-8"
    end

    test "TailwindMerge resolves conflicting background colors" do
      class ConflictBgComponent < Pom::Component
        option :variant, enums: [:normal, :danger], default: :normal

        define_styles(
          base: "bg-blue-500",
          variant: {
            danger: "bg-red-500",
          },
        )
      end

      component = ConflictBgComponent.new(variant: :danger)
      styles = component.styles_for(variant: component.variant)

      # TailwindMerge should keep only bg-red-500, not both
      refute_includes styles, "bg-blue-500"
      assert_includes styles, "bg-red-500"
    end

    test "TailwindMerge preserves non-conflicting classes" do
      class ConflictMixedComponent < Pom::Component
        option :variant, enums: [:normal, :large], default: :normal

        define_styles(
          base: "flex items-center p-4 bg-blue-500",
          variant: {
            large: "p-8",
          },
        )
      end

      component = ConflictMixedComponent.new(variant: :large)
      styles = component.styles_for(variant: component.variant)

      # Non-conflicting classes should remain
      assert_includes styles, "flex"
      assert_includes styles, "items-center"
      # Conflicting p-4 should be removed, p-8 should remain
      refute_includes styles, "p-4"
      assert_includes styles, "p-8"
      # bg-blue-500 should remain (no conflict)
      assert_includes styles, "bg-blue-500"
    end

    # Tests for boolean style_key values
    test "resolves boolean style_key with disabled true" do
      component = BooleanStyleKeyComponent.new(disabled: true, variant: :solid)
      styles = component.styles_for(disabled: component.disabled, variant: component.variant)

      # Should include base styles
      assert_includes styles, "btn"
      assert_includes styles, "font-medium"
      # Should include styles for disabled: true
      assert_includes styles, "opacity-50"
      assert_includes styles, "cursor-not-allowed"
      assert_includes styles, "pointer-events-none"
      # Should not include styles for disabled: false
      refute_includes styles, "cursor-pointer"
      refute_includes styles, "hover:opacity-80"
      # Should still include variant styles
      assert_includes styles, "bg-blue-500"
      assert_includes styles, "text-white"
    end

    test "resolves boolean style_key with disabled false" do
      component = BooleanStyleKeyComponent.new(disabled: false, variant: :outline)
      styles = component.styles_for(disabled: component.disabled, variant: component.variant)

      # Should include base styles
      assert_includes styles, "btn"
      assert_includes styles, "font-medium"
      # Should include styles for disabled: false
      assert_includes styles, "cursor-pointer"
      assert_includes styles, "hover:opacity-80"
      # Should not include styles for disabled: true
      refute_includes styles, "opacity-50"
      refute_includes styles, "cursor-not-allowed"
      refute_includes styles, "pointer-events-none"
      # Should still include variant styles
      assert_includes styles, "border"
      assert_includes styles, "border-blue-500"
    end

    test "boolean style_key uses default value when not provided" do
      component = BooleanStyleKeyComponent.new(variant: :solid)
      styles = component.styles_for(disabled: component.disabled, variant: component.variant)

      # Default is false, so should include cursor-pointer
      assert_includes styles, "cursor-pointer"
      assert_includes styles, "hover:opacity-80"
      refute_includes styles, "opacity-50"
    end

    # Tests for lambda base styles
    test "resolves lambda base styles with default params" do
      component = LambdaBaseComponent.new(variant: :solid)
      styles = component.styles_for(variant: component.variant, color: component.color, disabled: component.disabled)

      # Should include base classes from lambda
      assert_includes styles, "component"
      assert_includes styles, "rounded"
      assert_includes styles, "bg-blue-100"
      # Should not include disabled styles
      refute_includes styles, "opacity-50"
      refute_includes styles, "cursor-not-allowed"
      # Should include variant styles
      assert_includes styles, "font-bold"
      assert_includes styles, "shadow-md"
    end

    test "resolves lambda base styles with custom color" do
      component = LambdaBaseComponent.new(variant: :outline, color: "red")
      styles = component.styles_for(variant: component.variant, color: component.color, disabled: component.disabled)

      # Should include base classes with custom color
      assert_includes styles, "component"
      assert_includes styles, "rounded"
      assert_includes styles, "bg-red-100"
      # Should include outline variant styles
      assert_includes styles, "border-2"
    end

    test "resolves lambda base styles with disabled true" do
      component = LambdaBaseComponent.new(variant: :solid, color: "green", disabled: true)
      styles = component.styles_for(variant: component.variant, color: component.color, disabled: component.disabled)

      # Should include base classes
      assert_includes styles, "component"
      assert_includes styles, "rounded"
      assert_includes styles, "bg-green-100"
      # Should include disabled styles from lambda
      assert_includes styles, "opacity-50"
      assert_includes styles, "cursor-not-allowed"
      # Should still include variant styles
      assert_includes styles, "font-bold"
      assert_includes styles, "shadow-md"
    end

    test "lambda base styles combined with variant styles" do
      component = LambdaBaseComponent.new(variant: :outline, color: "purple", disabled: false)
      styles = component.styles_for(variant: component.variant, color: component.color, disabled: component.disabled)

      # Base from lambda
      assert_includes styles, "component"
      assert_includes styles, "rounded"
      assert_includes styles, "bg-purple-100"
      # Variant styles
      assert_includes styles, "border-2"
      # Not disabled
      refute_includes styles, "opacity-50"
    end
  end
end
