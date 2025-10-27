# frozen_string_literal: true

require "test_helper"

module Pom
  class OptionHelperTest < ActiveSupport::TestCase
    include Pom::Helpers::OptionHelper
    include Pom::Helpers::StimulusHelper

    test "merges options from right to left" do
      opts1 = { id: "first", class: "btn" }
      opts2 = { id: "second", class: "btn-large" }
      result = merge_options(opts1, opts2)

      assert_equal({ id: "second", class: "btn btn-large" }, result)
    end

    test "merges Tailwind classes using tailwind_merge" do
      opts1 = { class: "bg-blue-500 text-white p-4" }
      opts2 = { class: ["bg-red-500", "p-6"] }
      result = merge_options(opts1, opts2)

      assert_equal({ class: "text-white bg-red-500 p-6" }, result)
    end

    test "handles conflicting Tailwind classes" do
      opts1 = { class: "text-left text-blue-500" }
      opts2 = { class: "text-right text-red-500" }
      result = merge_options(opts1, opts2)

      assert_equal({ class: "text-right text-red-500" }, result)
    end

    test "merges data attributes with concatenation for action and controller" do
      opts1 = { data: { controller: "modal", action: "click->modal#open", custom: "old" } }
      opts2 = { data: { controller: "tooltip", action: "hover->tooltip#show", custom: "new" } }
      result = merge_options(opts1, opts2)

      expected = {
        data: {
          controller: "modal tooltip",
          action: "click->modal#open hover->tooltip#show",
          custom: "new",
        },
      }
      assert_equal(expected, result)
    end

    test "handles nil or empty options" do
      opts1 = { class: "btn" }
      opts2 = nil
      opts3 = {}
      result = merge_options(opts1, opts2, opts3)

      assert_equal({ class: "btn" }, result)
    end
  end
end
