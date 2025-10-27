# frozen_string_literal: true

Rails.application.routes.draw do
  mount Pom::Engine => "/pom"
end
