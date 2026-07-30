Designbook::Engine.routes.draw do
  root to: "pages#show", defaults: { slug: "index" }
  get "search", to: "search#index", as: :search
  get "assets/*path", to: "assets#show", as: :asset, format: false
  get "/*slug", to: "pages#show", as: :page
end
