Rails.application.routes.draw do
  mount Rails::Keyserver::Engine => "/ks"
end
