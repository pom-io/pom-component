# frozen_string_literal: true

require_relative "lib/pom/version"

Gem::Specification.new do |spec|
  spec.name        = "pom-component"
  spec.version     = Pom::VERSION
  spec.authors     = ["Hoang Nghiem"]
  spec.email       = ["hoangnghiem1711@gmail.com"]
  spec.homepage    = "https://github.com/pom-io/pom-component"
  spec.summary     = "A base component class and helpers for Rails with Tailwind CSS."
  spec.description = "This gem provides a base component class and helper utilities for building ViewComponents in Rails applications, with built-in Tailwind CSS support."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = "https://pom-io.github.io/pom-component"
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/v#{spec.version}"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://pom-io.github.io/pom-component"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.2.0"

  spec.add_runtime_dependency "rails", "~> 7.1"
  spec.add_runtime_dependency "tailwind_merge", "~> 1.0"
  spec.add_runtime_dependency "view_component", "~> 4.0"

  spec.add_development_dependency("capybara", "~> 3.0")
  spec.add_development_dependency("minitest", "~> 5.0")
  spec.add_development_dependency("rubocop", "~> 1.75")
end
