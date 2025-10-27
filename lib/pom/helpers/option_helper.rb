# frozen_string_literal: true

module Pom
  module Helpers
    module OptionHelper
      # Merges multiple option hashes from right to left, handling CSS classes and data attributes.
      # @param options [Array<Hash>] List of option hashes to merge
      # @return [Hash] Merged options hash
      def merge_options(*options)
        options.reduce({}) do |merged, opts|
          next merged if opts.nil? || opts.empty?

          merged.merge(opts) do |key, old_val, new_val|
            case key
            when :class
              merge_classes(old_val, new_val)
            when :data
              merge_data(old_val, new_val)
            else
              new_val
            end
          end
        end
      end

      private

      # Merges CSS classes using tailwind_merge gem, handling strings, arrays, or nil.
      # @param old_val [String, Array, nil] Existing class value
      # @param new_val [String, Array, nil] New class value
      # @return [String] Merged class string
      def merge_classes(old_val, new_val)
        old_classes = normalize_classes(old_val)
        new_classes = normalize_classes(new_val)
        TailwindMerge::Merger.new.merge([old_classes, new_classes].join(" "))
      end

      # Normalizes class values to a string, handling strings, arrays, or nil.
      # @param value [String, Array, nil] Class value
      # @return [String] Normalized class string
      def normalize_classes(value)
        case value
        when String
          value.strip
        when Array
          value.flatten.map(&:to_s).reject(&:empty?).join(" ").strip
        else
          ""
        end
      end

      # Merges data attribute hashes, with special handling for data-action and data-controller.
      # @param old_val [Hash, nil] Existing data hash
      # @param new_val [Hash, nil] New data hash
      # @return [Hash] Merged data hash
      def merge_data(old_val, new_val)
        old_data = old_val || {}
        new_data = new_val || {}

        old_data.merge(new_data) do |key, old_data_val, new_data_val|
          if ["action", "controller"].include?(key.to_s)
            [old_data_val, new_data_val].uniq.compact.join(" ").strip
          else
            new_data_val
          end
        end
      end
    end
  end
end
