# frozen_string_literal: true

module Pom
  # Base Rails ViewComponent class with DSL for options, enum validation, extra options capture, and required options enforcement
  class Component < ViewComponent::Base
    include Pom::OptionDsl
    include Pom::Styleable
    include Pom::Helpers::OptionHelper
    include Pom::Helpers::ViewHelper
    include Pom::Helpers::StimulusHelper

    # Initialize component with options, applying defaults, validation, capturing extra options, and enforcing required options
    def initialize(**kwargs)
      super()
      initialize_options(**kwargs)
    end

    def component_name
      self.class.name.demodulize.chomp("Component").underscore.dasherize
    end

    def auto_id
      [component_name, uid].compact_blank.join("-")
    end

    def uid
      @uid ||= SecureRandom.hex(8 / 2)
    end
  end
end
