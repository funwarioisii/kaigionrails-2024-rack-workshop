# frozen_string_literal: true

require 'rack/runtime'
require 'rack/auth/basic'

class App
  def call(env)
    binding.irb
    [200, {}, ['hello']]
  end
end

class Middleware
  def initialize(app, name)
    @app = app
    @name = name
  end

  def call(env)
    status, headers, body = @app.call(env)
    headers['hello'] = @name
    [status, headers, body]
  end
end

class ExitMiddleware
  def initialize(app, mask)
    @app = app
    @mask = mask
  end

  def call(env)
    status, headers, body = @app.call(env)
    headers['hello'] = @mask
    [status, headers, body]
  end
end

use Middleware, 'rails'
use Rack::Runtime
use Rack::Auth::Basic do |username, password|
  username == 'rubyist' && password == 'onrack'
end
run App.new
use ExitMiddleware, 'nani'
