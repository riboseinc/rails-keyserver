Rails.application.routes.draw do
  mount Rails::Keyserver::Engine => "/rails-keyserver"
end
