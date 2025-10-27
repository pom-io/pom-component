# frozen_string_literal: true

require "test_helper"
require "active_support/core_ext/string/inflections"

module Pom
  module Helpers
    class StimulusHelperTest < ActiveSupport::TestCase
      # Test component class that includes StimulusHelper
      class TestComponent
        include Pom::Helpers::StimulusHelper

        attr_reader :stimulus

        def initialize(stimulus: nil)
          @stimulus = stimulus
        end
      end

      # Component with no stimulus method
      class NoStimulusComponent
        include Pom::Helpers::StimulusHelper
      end

      # Tests for stimulus_value
      test "stimulus_value generates correct data attribute with string name" do
        component = TestComponent.new(stimulus: "dropdown")
        result = component.stimulus_value("open", true)

        assert_equal({ "data-dropdown-open-value" => true }, result)
      end

      test "stimulus_value generates correct data attribute with symbol name" do
        component = TestComponent.new(stimulus: "dropdown")
        result = component.stimulus_value(:open, false)

        assert_equal({ "data-dropdown-open-value" => false }, result)
      end

      test "stimulus_value dasherizes multi-word names" do
        component = TestComponent.new(stimulus: "dropdown")
        result = component.stimulus_value(:max_items, 10)

        assert_equal({ "data-dropdown-max-items-value" => 10 }, result)
      end

      test "stimulus_value dasherizes controller name" do
        component = TestComponent.new(stimulus: "DropdownMenu")
        result = component.stimulus_value(:open, true)

        assert_equal({ "data-dropdown-menu-open-value" => true }, result)
      end

      test "stimulus_value accepts explicit stimulus controller" do
        component = TestComponent.new(stimulus: "dropdown")
        result = component.stimulus_value(:open, true, stimulus: "modal")

        assert_equal({ "data-modal-open-value" => true }, result)
      end

      test "stimulus_value handles string values" do
        component = TestComponent.new(stimulus: "search")
        result = component.stimulus_value(:query, "test query")

        assert_equal({ "data-search-query-value" => "test query" }, result)
      end

      test "stimulus_value handles numeric values" do
        component = TestComponent.new(stimulus: "counter")
        result = component.stimulus_value(:count, 42)

        assert_equal({ "data-counter-count-value" => 42 }, result)
      end

      test "stimulus_value raises error for blank name" do
        component = TestComponent.new(stimulus: "dropdown")

        error = assert_raises(ArgumentError) do
          component.stimulus_value("", true)
        end
        assert_equal "Name cannot be blank", error.message
      end

      test "stimulus_value raises error for whitespace-only name" do
        component = TestComponent.new(stimulus: "dropdown")

        error = assert_raises(ArgumentError) do
          component.stimulus_value("   ", true)
        end
        assert_equal "Name cannot be blank", error.message
      end

      # Tests for stimulus_target
      test "stimulus_target generates correct data attribute" do
        component = TestComponent.new(stimulus: "dropdown")
        result = component.stimulus_target("menu")

        assert_equal({ "data-dropdown-target" => "menu" }, result)
      end

      test "stimulus_target accepts symbol name" do
        component = TestComponent.new(stimulus: "dropdown")
        result = component.stimulus_target(:menu)

        assert_equal({ "data-dropdown-target" => "menu" }, result)
      end

      test "stimulus_target dasherizes controller name" do
        component = TestComponent.new(stimulus: "DropdownMenu")
        result = component.stimulus_target(:menu)

        assert_equal({ "data-dropdown-menu-target" => "menu" }, result)
      end

      test "stimulus_target accepts explicit stimulus controller" do
        component = TestComponent.new(stimulus: "dropdown")
        result = component.stimulus_target(:menu, stimulus: "modal")

        assert_equal({ "data-modal-target" => "menu" }, result)
      end

      test "stimulus_target raises error for blank name" do
        component = TestComponent.new(stimulus: "dropdown")

        error = assert_raises(ArgumentError) do
          component.stimulus_target("")
        end
        assert_equal "Name cannot be blank", error.message
      end

      # Tests for stimulus_class
      test "stimulus_class generates correct data attribute" do
        component = TestComponent.new(stimulus: "dropdown")
        result = component.stimulus_class(:open, "block")

        assert_equal({ "data-dropdown-open-class" => "block" }, result)
      end

      test "stimulus_class dasherizes multi-word names" do
        component = TestComponent.new(stimulus: "dropdown")
        result = component.stimulus_class(:menu_open, "bg-blue-500")

        assert_equal({ "data-dropdown-menu-open-class" => "bg-blue-500" }, result)
      end

      test "stimulus_class accepts explicit stimulus controller" do
        component = TestComponent.new(stimulus: "dropdown")
        result = component.stimulus_class(:active, "text-white", stimulus: "tab")

        assert_equal({ "data-tab-active-class" => "text-white" }, result)
      end

      test "stimulus_class raises error for blank name" do
        component = TestComponent.new(stimulus: "dropdown")

        error = assert_raises(ArgumentError) do
          component.stimulus_class("", "block")
        end
        assert_equal "Name cannot be blank", error.message
      end

      # Tests for stimulus_action
      test "stimulus_action generates action with hash of events" do
        component = TestComponent.new(stimulus: "dropdown")
        result = component.stimulus_action({ click: :toggle, mouseenter: :show })

        assert_equal({ "data-action" => "click->dropdown#toggle mouseenter->dropdown#show" }, result)
      end

      test "stimulus_action generates action with symbol" do
        component = TestComponent.new(stimulus: "dropdown")
        result = component.stimulus_action(:toggle)

        assert_equal({ "data-action" => "dropdown#toggle" }, result)
      end

      test "stimulus_action generates action with string" do
        component = TestComponent.new(stimulus: "dropdown")
        result = component.stimulus_action("toggle")

        assert_equal({ "data-action" => "dropdown#toggle" }, result)
      end

      test "stimulus_action dasherizes controller name" do
        component = TestComponent.new(stimulus: "DropdownMenu")
        result = component.stimulus_action(:toggle)

        assert_equal({ "data-action" => "dropdown-menu#toggle" }, result)
      end

      test "stimulus_action accepts explicit stimulus controller" do
        component = TestComponent.new(stimulus: "dropdown")
        result = component.stimulus_action(:toggle, stimulus: "modal")

        assert_equal({ "data-action" => "modal#toggle" }, result)
      end

      test "stimulus_action with hash accepts symbols and strings" do
        component = TestComponent.new(stimulus: "form")
        result = component.stimulus_action({ submit: "validate", "change": :update })

        action = result["data-action"]
        assert_includes action, "submit->form#validate"
        assert_includes action, "change->form#update"
      end

      test "stimulus_action raises error when controller included manually in string" do
        component = TestComponent.new(stimulus: "dropdown")

        error = assert_raises(ArgumentError) do
          component.stimulus_action("click->dropdown#toggle")
        end
        assert_match(/Do not include controller name manually/, error.message)
      end

      test "stimulus_action raises error for invalid format" do
        component = TestComponent.new(stimulus: "dropdown")

        error = assert_raises(ArgumentError) do
          component.stimulus_action(123)
        end
        assert_match(/Invalid format for stimulus_action/, error.message)
      end

      # Tests for stimulus_controller
      test "stimulus_controller returns dasherized controller name" do
        component = TestComponent.new(stimulus: "DropdownMenu")

        assert_equal "dropdown-menu", component.stimulus_controller
      end

      test "stimulus_controller returns single word controller" do
        component = TestComponent.new(stimulus: "dropdown")

        assert_equal "dropdown", component.stimulus_controller
      end

      test "stimulus_controller converts symbol to dasherized string" do
        component = TestComponent.new(stimulus: :DropdownMenu)

        assert_equal "dropdown-menu", component.stimulus_controller
      end

      test "stimulus_controller raises error when no stimulus method exists" do
        component = NoStimulusComponent.new

        error = assert_raises(ArgumentError) do
          component.stimulus_controller
        end
        assert_match(/No Stimulus controller available/, error.message)
      end

      test "stimulus_controller raises error when stimulus is nil" do
        component = TestComponent.new(stimulus: nil)

        error = assert_raises(ArgumentError) do
          component.stimulus_controller
        end
        assert_match(/No Stimulus controller available/, error.message)
      end

      test "stimulus_controller raises error when stimulus is blank string" do
        component = TestComponent.new(stimulus: "")

        error = assert_raises(ArgumentError) do
          component.stimulus_controller
        end
        assert_equal "Stimulus controller cannot be blank", error.message
      end

      test "stimulus_controller raises error when stimulus is whitespace" do
        component = TestComponent.new(stimulus: "   ")

        error = assert_raises(ArgumentError) do
          component.stimulus_controller
        end
        assert_equal "Stimulus controller cannot be blank", error.message
      end

      # Integration tests
      test "all helpers work together for building stimulus attributes" do
        component = TestComponent.new(stimulus: "dropdown")

        attrs = {}
        attrs.merge!(component.stimulus_target(:menu))
        attrs.merge!(component.stimulus_value(:open, false))
        attrs.merge!(component.stimulus_class(:open, "block"))
        attrs.merge!(component.stimulus_action({ click: :toggle }))

        assert_equal "menu", attrs["data-dropdown-target"]
        assert_equal false, attrs["data-dropdown-open-value"]
        assert_equal "block", attrs["data-dropdown-open-class"]
        assert_equal "click->dropdown#toggle", attrs["data-action"]
      end

      test "helpers work with different controllers via explicit stimulus param" do
        component = TestComponent.new(stimulus: "dropdown")

        dropdown_target = component.stimulus_target(:menu)
        modal_target = component.stimulus_target(:dialog, stimulus: "modal")

        assert_equal({ "data-dropdown-target" => "menu" }, dropdown_target)
        assert_equal({ "data-modal-target" => "dialog" }, modal_target)
      end

      # Edge cases
      test "stimulus_value serializes array values to JSON" do
        component = TestComponent.new(stimulus: "list")
        result = component.stimulus_value(:items, ["a", "b", "c"])

        assert_equal({ "data-list-items-value" => '["a","b","c"]' }, result)
      end

      test "stimulus_value serializes hash values to JSON" do
        component = TestComponent.new(stimulus: "config")
        result = component.stimulus_value(:settings, { theme: "dark" })

        assert_equal({ "data-config-settings-value" => '{"theme":"dark"}' }, result)
      end

      test "stimulus_value does not serialize primitive values" do
        component = TestComponent.new(stimulus: "counter")

        string_result = component.stimulus_value(:name, "test")
        assert_equal({ "data-counter-name-value" => "test" }, string_result)

        number_result = component.stimulus_value(:count, 42)
        assert_equal({ "data-counter-count-value" => 42 }, number_result)

        bool_result = component.stimulus_value(:active, true)
        assert_equal({ "data-counter-active-value" => true }, bool_result)
      end

      test "stimulus_action with empty hash" do
        component = TestComponent.new(stimulus: "dropdown")
        result = component.stimulus_action({})

        # Empty hash produces empty string
        assert_equal({ "data-action" => "" }, result)
      end

      test "stimulus_target preserves target name as-is" do
        component = TestComponent.new(stimulus: "dropdown")
        result = component.stimulus_target("menuItem")

        # Target name should not be dasherized, only controller name
        assert_equal({ "data-dropdown-target" => "menuItem" }, result)
      end

      test "stimulus_target accepts array of targets" do
        component = TestComponent.new(stimulus: "dropdown")
        result = component.stimulus_target([:menu, :button])

        assert_equal({ "data-dropdown-target" => "menu button" }, result)
      end

      test "stimulus_target with array converts all elements to strings" do
        component = TestComponent.new(stimulus: "modal")
        result = component.stimulus_target(["dialog", :overlay, "backdrop"])

        assert_equal({ "data-modal-target" => "dialog overlay backdrop" }, result)
      end

      test "stimulus_target raises error for empty array" do
        component = TestComponent.new(stimulus: "dropdown")

        error = assert_raises(ArgumentError) do
          component.stimulus_target([])
        end
        assert_equal "Name cannot be blank", error.message
      end

      test "stimulus_target raises error for array with blank values" do
        component = TestComponent.new(stimulus: "dropdown")

        error = assert_raises(ArgumentError) do
          component.stimulus_target([:menu, "", :button])
        end
        assert_equal "Name cannot be blank", error.message
      end
    end
  end
end
