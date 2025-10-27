# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module Pom
  module Helpers
    # Provides helper methods for generating Stimulus.js data attributes in Rails views or ViewComponents.
    module StimulusHelper
      # Generates a Stimulus data value attribute.
      # @param name [Symbol, String] The name of the value.
      # @param value [Object] The value to assign. Complex objects (Array, Hash) are JSON-encoded.
      # @param stimulus [String, Symbol, nil] The Stimulus controller name (defaults to `stimulus_controller`).
      # @return [Hash] A hash with the attribute key and value.
      def stimulus_value(name, value, stimulus: nil)
        raise ArgumentError, "Name cannot be blank" if name.to_s.strip.empty?

        controller_name = stimulus ? stimulus.to_s.underscore.dasherize : stimulus_controller
        key = "data-#{controller_name}-#{name.to_s.underscore.dasherize}-value"

        # Stimulus expects JSON for complex values (arrays, hashes)
        serialized_value = case value
        when Array, Hash
          value.to_json
        else
          value
        end

        { key => serialized_value }
      end

      # Generates a Stimulus target attribute.
      # @param name [Symbol, String, Array] The target name(s). Can be a single target or array of targets.
      # @param stimulus [String, Symbol, nil] The Stimulus controller name (defaults to `stimulus_controller`).
      # @return [Hash] A hash with the attribute key and target name(s).
      #
      # @example Single target
      #   stimulus_target(:menu)
      #   # => { "data-dropdown-target" => "menu" }
      #
      # @example Multiple targets
      #   stimulus_target([:menu, :button])
      #   # => { "data-dropdown-target" => "menu button" }
      def stimulus_target(name, stimulus: nil)
        names = Array(name)
        raise ArgumentError, "Name cannot be blank" if names.empty? || names.any? { |n| n.to_s.strip.empty? }

        controller_name = stimulus ? stimulus.to_s.underscore.dasherize : stimulus_controller
        key = "data-#{controller_name}-target"
        target_value = names.map(&:to_s).join(" ")

        { key => target_value }
      end

      # Generates a Stimulus class attribute.
      # @param name [Symbol, String] The class name.
      # @param value [String] The CSS class value.
      # @param stimulus [String, Symbol, nil] The Stimulus controller name (defaults to `stimulus_controller`).
      # @return [Hash] A hash with the attribute key and class value.
      def stimulus_class(name, value, stimulus: nil)
        raise ArgumentError, "Name cannot be blank" if name.to_s.strip.empty?

        controller_name = stimulus ? stimulus.to_s.underscore.dasherize : stimulus_controller
        key = "data-#{controller_name}-#{name.to_s.underscore.dasherize}-class"
        { key => value }
      end

      # Generates a Stimulus action attribute.
      # @param action_map [Hash, Symbol, String] The action definition (e.g., `{ click: :toggle }` or `:toggle`).
      # @param stimulus [String, Symbol, nil] The Stimulus controller name (defaults to `stimulus_controller`).
      # @return [Hash] A hash with the action attribute key and value.
      #
      # @example Hash format with multiple events
      #   stimulus_action({ click: :toggle, mouseenter: :show })
      #   # => { "data-action" => "click->dropdown#toggle mouseenter->dropdown#show" }
      #
      # @example Symbol/String format
      #   stimulus_action(:toggle)
      #   # => { "data-action" => "dropdown#toggle" }
      def stimulus_action(action_map, stimulus: nil)
        controller_name = stimulus ? stimulus.to_s.underscore.dasherize : stimulus_controller

        action_string = case action_map
        when Hash
          return { "data-action" => "" } if action_map.empty?

          action_map.map { |event, method| "#{event}->#{controller_name}##{method}" }.join(" ")
        when Symbol, String
          str = action_map.to_s
          if str.include?("->")
            raise ArgumentError,
              "Do not include controller name manually. Use `stimulus:` or `stimulus_controller` to set the controller."
          end
          "#{controller_name}##{str}"
        else
          raise ArgumentError, "Invalid format for stimulus_action: must be a Hash, Symbol, or String"
        end

        { "data-action" => action_string }
      end

      # Retrieves the Stimulus controller name in dasherized style.
      # @return [String] The controller name.
      # @raise [ArgumentError] If no controller is defined or if the controller name is blank.
      def stimulus_controller
        controller = respond_to?(:stimulus) ? stimulus : nil
        controller ||= raise ArgumentError,
          "No Stimulus controller available. Provide one explicitly via `stimulus:` or define a `stimulus` method."
        raise ArgumentError, "Stimulus controller cannot be blank" if controller.to_s.strip.empty?

        controller.to_s.underscore.dasherize
      end
    end
  end
end
