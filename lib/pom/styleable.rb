# frozen_string_literal: true

module Pom
  module Styleable
    class << self
      def included(base)
        base.extend(ClassMethods)
      end
    end

    module ClassMethods
      # Define styles for a component
      # @param group [Symbol] The style group name (defaults to :default)
      # @param styles [Hash] The styles definition
      #
      # Examples:
      #   define_styles(base: "btn")
      #   define_styles(:root, base: "container")
      #   define_styles(
      #     base: { default: "btn", hover: "hover:opacity-80" },
      #     variant: { solid: "bg-blue-500", outline: "border" }
      #   )
      def define_styles(group = :default, **styles)
        # If first argument is a hash, it's actually the styles with default group
        if group.is_a?(Hash)
          styles = group
          group = :default
        end

        @style_definitions ||= {}
        @style_definitions[group] ||= {}

        # Merge with existing styles for this group (supports inheritance)
        styles.each do |style_key, style_value|
          @style_definitions[group][style_key] = if @style_definitions[group][style_key].is_a?(Hash) && style_value.is_a?(Hash)
            @style_definitions[group][style_key].merge(style_value)
          else
            style_value
          end
        end
      end

      # Get style definitions for this class and its ancestors
      def style_definitions
        definitions = {}

        # Collect style definitions from ancestors (inheritance support)
        ancestors.reverse.each do |ancestor|
          next unless ancestor.respond_to?(:style_definitions_without_inheritance, true)

          ancestor_defs = ancestor.send(:style_definitions_without_inheritance)
          ancestor_defs&.each do |group, styles|
            definitions[group] ||= {}
            styles.each do |style_key, style_value|
              definitions[group][style_key] = if definitions[group][style_key].is_a?(Hash) && style_value.is_a?(Hash)
                definitions[group][style_key].merge(style_value)
              else
                style_value
              end
            end
          end
        end

        definitions
      end

      private

      def style_definitions_without_inheritance
        @style_definitions
      end
    end

    # Compose styles based on provided keys and values
    # @param group [Symbol] The style group to use (defaults to :default)
    # @param options [Hash] Style keys and their values, plus any extra params
    # @return [String] The composed Tailwind class string merged using TailwindMerge
    #
    # Examples:
    #   styles_for(variant: :solid, color: :red)
    #   styles_for(:root, variant: :outline)
    #   styles_for(variant: :solid, custom: true)
    def styles_for(group = :default, **options)
      # If first argument is a hash, it's actually the options with default group
      if group.is_a?(Hash)
        options = group
        group = :default
      end

      definitions = self.class.style_definitions[group]
      return "" unless definitions

      result_classes = []

      # Process base styles first
      if definitions[:base]
        base_styles = resolve_style_value(definitions[:base], options)
        result_classes << base_styles if base_styles
      end

      # Process other style keys
      definitions.each do |style_key, style_config|
        next if style_key == :base # Already processed
        next unless options.key?(style_key) # Only process if key is provided

        option_value = options[style_key]
        next if option_value.nil? # Skip nil values

        if style_config.is_a?(Hash)
          # Style config is a hash of variant values
          # Support boolean values, symbol values, and string values
          style_value = if option_value.is_a?(TrueClass) || option_value.is_a?(FalseClass)
            # For boolean values, convert to symbol (:true or :false)
            # because { true: "..." } in Ruby creates a symbol key :true, not boolean key true
            style_config[option_value.to_s.to_sym]
          else
            # For other values, try symbol and string conversions
            style_config[option_value.to_sym] || style_config[option_value.to_s]
          end
          resolved = resolve_style_value(style_value, options)
        else
          # Style config is a direct value (string or lambda)
          resolved = resolve_style_value(style_config, options)
        end
        result_classes << resolved if resolved
      end

      # Use TailwindMerge to merge classes and resolve conflicts
      merged_classes = result_classes.compact.join(" ")
      merged_classes.empty? ? "" : TailwindMerge::Merger.new.merge(merged_classes)
    end

    private

    # Resolve a style value to a string
    # Handles strings, hashes, and lambdas
    def resolve_style_value(value, options)
      case value
      when String
        value
      when Hash
        # Hash of sub-styles (like { default: "...", hover: "..." })
        value.values.map { |v| resolve_style_value(v, options) }.compact.join(" ")
      when Proc
        # Lambda that receives all options for dynamic computation
        result = value.call(**options)
        result.is_a?(String) ? result : result.to_s
      else
        value&.to_s
      end
    end
  end
end
