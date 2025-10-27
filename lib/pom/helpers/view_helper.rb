# frozen_string_literal: true

module Pom
  module Helpers
    module ViewHelper
      class UndefinedComponentError < StandardError; end

      def method_missing(method_name, *args, **kwargs, &block)
        prefix_match = component_prefixes.find { |prefix| method_name.to_s.start_with?("#{prefix}_") }

        if prefix_match
          class_name = component_class_name(method_name, prefix_match)

          begin
            component_class = class_name.constantize
          rescue NameError => e
            if e.message.include?(class_name)
              raise UndefinedComponentError, "Component class '#{class_name}' is not defined"
            else
              raise e
            end
          end

          render(component_class.new(*args, **kwargs), &block)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        prefix_match = component_prefixes.find { |prefix| method_name.to_s.start_with?("#{prefix}_") }

        if prefix_match
          class_name = component_class_name(method_name, prefix_match)
          # Check if the constant exists by attempting to constantize it
          begin
            class_name.constantize
            true
          rescue NameError
            false
          end
        else
          super
        end
      end

      private

      def component_prefixes
        Pom.configuration.component_prefixes
      end

      def component_class_name(method_name, prefix)
        component_name = method_name.to_s.sub(/^#{prefix}_/, "").camelize
        "#{prefix.camelize}::#{component_name}Component"
      end
    end
  end
end
