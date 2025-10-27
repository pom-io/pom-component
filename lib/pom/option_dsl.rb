# frozen_string_literal: true

module Pom
  module OptionDsl
    # Sentinel object to distinguish between nil and no default
    NO_DEFAULT = Object.new.freeze
    private_constant :NO_DEFAULT

    class << self
      def included(base)
        base.extend(ClassMethods)
        base.class_eval do
          # Instance variable to store extra options that aren't defined
          attr_reader(:extra_options)
        end
      end
    end

    module ClassMethods
      attr_reader :options

      # Helper methods for accessing option metadata
      def enum_values_for(option_name)
        meta = @options&.[](option_name.to_sym)
        meta&.dig(:enums)
      end

      def default_value_for(option_name)
        meta = @options&.[](option_name.to_sym)
        return unless meta

        default_val = meta[:default]
        return if default_val.equal?(NO_DEFAULT)

        default_val.respond_to?(:call) ? default_val.call : default_val
      end

      def required_options
        return [] unless @options

        @options.filter_map do |name, config|
          name if config[:required] && config[:default].equal?(NO_DEFAULT)
        end
      end

      def optional_options
        return [] unless @options

        @options.filter_map do |name, config|
          name unless config[:required] && config[:default].equal?(NO_DEFAULT)
        end
      end

      private

      # Initialize options hash for the class, inheriting from parent if applicable
      def inherited(subclass)
        super
        subclass.instance_variable_set(:@options, (@options || {}).dup)
      end

      # DSL for defining options with enums, defaults, and required flag
      def option(name, enums: nil, default: NO_DEFAULT, required: false)
        @options ||= {}
        @options[name.to_sym] = {
          enums: enums&.map(&:to_sym),
          default: default,
          required: required,
        }

        # Define getter method for the option
        define_method(name) do
          value = instance_variable_get(:"@#{name}")
          return value unless value.nil?

          default_val = self.class.options[name.to_sym][:default]
          return if default_val.equal?(NO_DEFAULT)

          default_val.respond_to?(:call) ? default_val.call : default_val
        end

        # Define setter method with validation for enums
        define_method(:"#{name}=") do |value|
          option_config = self.class.options[name.to_sym]
          enums = option_config[:enums]

          if enums && !value.nil?
            # Convert value to symbol if it's a string for comparison
            sym_value = value.is_a?(String) ? value.to_sym : value

            # Validate against enums
            if enums.exclude?(sym_value)
              raise ArgumentError, "Invalid value for #{name}: #{value}. Must be one of #{enums.join(", ")}"
            end

            # Store the converted symbol value for consistency
            value = sym_value
          end

          instance_variable_set(:"@#{name}", value)
        end

        # Define predicate method for boolean-style checking
        define_method(:"#{name}?") do
          send(name).present?
        end
      end
    end

    # Initialize options processing - call this from your initialize method
    def initialize_options(**kwargs)
      @extra_options = {}
      defined_options = self.class.options || {}

      # Validate required options first
      validate_required_options!(defined_options, kwargs)

      # Process provided options
      process_provided_options!(defined_options, kwargs)

      # Set defaults for options not provided in kwargs
      set_default_values!(defined_options, kwargs)
    end

    # Utility method to get all option values as a hash
    def option_values
      return {} unless self.class.options

      self.class.options.keys.index_with do |name|
        send(name)
      end
    end

    # Check if an option is set (not nil and not default)
    def option_set?(name)
      return false unless self.class.options&.key?(name.to_sym)

      value = instance_variable_get(:"@#{name}")
      !value.nil?
    end

    # Reset an option to its default value
    def reset_option(name)
      name = name.to_sym
      return unless self.class.options&.key?(name)

      remove_instance_variable(:"@#{name}") if instance_variable_defined?(:"@#{name}")
    end

    private

    def validate_required_options!(defined_options, kwargs)
      defined_options.each do |name, config|
        next unless config[:required]
        next unless config[:default].equal?(NO_DEFAULT)
        next if kwargs.key?(name) || kwargs.key?(name.to_s)

        raise ArgumentError, "Missing required option: #{name}"
      end
    end

    def process_provided_options!(defined_options, kwargs)
      kwargs.each do |name, value|
        sym_name = name.to_sym

        if defined_options.key?(sym_name)
          send(:"#{sym_name}=", value)
        else
          @extra_options[sym_name] = value
        end
      end
    end

    def set_default_values!(defined_options, kwargs)
      defined_options.each do |name, config|
        next if kwargs.key?(name) || kwargs.key?(name.to_s)
        next if config[:default].equal?(NO_DEFAULT)

        send(:"#{name}=", config[:default])
      end
    end
  end
end
