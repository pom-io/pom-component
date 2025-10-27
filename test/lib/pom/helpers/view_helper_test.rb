# frozen_string_literal: true

require "test_helper"

module Pom
  class ViewHelperTest < ActiveSupport::TestCase
    include Pom::Helpers::ViewHelper

    # Test component in Pom namespace
    class ButtonComponent < Pom::Component
      option :variant, default: :primary

      def call
        content_tag(:button, content)
      end
    end

    test "component_class_name uses Pom namespace" do
      class_name = component_class_name(:pom_button)
      assert_equal "Pom::ButtonComponent", class_name
    end

    test "component_class_name converts snake_case to CamelCase" do
      class_name = component_class_name(:pom_user_profile_card)
      assert_equal "Pom::UserProfileCardComponent", class_name
    end

    test "component_class_name strips pom_ prefix" do
      class_name = component_class_name(:pom_test)
      assert_equal "Pom::TestComponent", class_name
    end

    test "method_missing raises UndefinedComponentError for undefined component" do
      error = assert_raises(Pom::Helpers::ViewHelper::UndefinedComponentError) do
        # This will try to render a component that doesn't exist
        pom_undefined_component_xyz
      end

      assert_match(/Component class 'Pom::UndefinedComponentXyzComponent' is not defined/, error.message)
    end
  end
end
