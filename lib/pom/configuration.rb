# frozen_string_literal: true

module Pom
  class Configuration
    attr_accessor :component_prefixes

    def initialize
      @component_prefixes = ["pom"]
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
