# frozen_string_literal: true

require "pom/version"

require "view_component"
require "tailwind_merge"

require "pom/option_dsl"
require "pom/styleable"

# Load helpers
require "pom/helpers/view_helper"
require "pom/helpers/option_helper"
require "pom/helpers/stimulus_helper"

require "pom/component"

require "pom/engine" if defined?(Rails)
