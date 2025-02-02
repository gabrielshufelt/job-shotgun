Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*' # Allow any origin, you can restrict this to specific URLs for production
    resource '*', headers: :any, methods: %i[get post patch put delete options]
  end
end
