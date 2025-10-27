# frozen_string_literal: true

require_relative "lib/pom/version"

Gem::Specification.new do |spec|
  spec.name        = "pom-component"
  spec.version     = Pom::VERSION
  spec.authors     = ["Hoang Nghiem"]
  spec.email       = ["hoangnghiem1711@gmail.com"]
  spec.homepage    = "https://github.com/hoangnghiem/pom-component"
  spec.summary     = "A UI component toolkit for Rails with Tailwind CSS integration."
  spec.description = "Pom provides reusable ViewComponents for Rails applications, leveraging Tailwind CSS for robust UI development."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "https://rubygems.pkg.github.com/hoangnghiem"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["github_repo"] = "ssh://github.com/hoangnghiem/pom-componentb"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.2.0"

  spec.add_runtime_dependency("rails", ">= 7.1.0")

  spec.add_dependency("tailwind_merge", "~> 1.0")
  spec.add_dependency("view_component", ">= 4.0")

  spec.add_development_dependency("capybara", "~> 3.0")
  spec.add_development_dependency("minitest", "~> 5.0")
  spec.add_development_dependency("rubocop", "~> 1.75")
end
