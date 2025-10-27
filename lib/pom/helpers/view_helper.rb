# frozen_string_literal: true

module Pom
  module Helpers
    module ViewHelper
      class UndefinedComponentError < StandardError; end

      def method_missing(method_name, *args, **kwargs, &block)
        if method_name.to_s.start_with?("pom_")
          class_name = component_class_name(method_name)

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
        if method_name.to_s.start_with?("pom_")
          class_name = component_class_name(method_name)
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

      def component_class_name(method_name)
        component_name = method_name.to_s.sub(/^pom_/, "").camelize
        "Pom::#{component_name}Component"
      end
    end
  end
end
