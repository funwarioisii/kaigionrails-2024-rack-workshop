# frozen_string_literal: true

require 'rack/request'
require 'rack/response'

class App
  def call(env)
    request = Rack::Request.new(env)
    case [request.request_method, request.path_info]
    in ['GET', '/']
      Rack::Response.new('It works!', 200).finish
    in 'GET', *rest
      raise unless rest.starts_with? '/hello'

      slug = rest.first.split('/hello/').last
      Rack::Response.new("Hello #{slug}", 200).finish
    end
  rescue StandardError
    Rack::Response.new('Not Found', 404).finish
  end
end

run App.new
