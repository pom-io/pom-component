# frozen_string_literal: true

module Pom
  class Engine < ::Rails::Engine
    isolate_namespace Pom

    initializer "pom.helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper Pom::Helpers::OptionHelper
        helper Pom::Helpers::ViewHelper
        helper Pom::Helpers::StimulusHelper
      end
    end
  end
end
