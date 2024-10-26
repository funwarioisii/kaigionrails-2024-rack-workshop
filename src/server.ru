# frozen_string_literal: true

require 'socket'
require 'logger'

require 'rack/rewindable_input'

class App
  def call(env)
    if env['PATH_INFO'] == '/'
      [200, {}, ['It works!']]
    else
      [404, {}, ['Not Found']]
    end
  end
end

class SimpleServer
  def self.run(app, **options)
    new(app, options).start
  end

  def initialize(app, options)
    @app = app
    @options = options
    @logger = Logger.new($stdout)
  end

  def start
    @logger.info 'SimpleServer starting...'
    server = TCPServer.new(@options[:Port].to_i)

    loop do
      client = server.accept
      request_line = client.gets&.chomp
      # リクエストラインの解析
      %r{^GET (?<path>.+) HTTP/1.1$}.match(request_line)
      path = Regexp.last_match(:path)

      sleep 5
      env = {
        Rack::REQUEST_METHOD => 'GET',
        Rack::SCRIPT_NAME => '',
        Rack::PATH_INFO => path,
        Rack::SERVER_NAME => @options[:Host],
        Rack::SERVER_PORT => @options[:Port].to_s,
        Rack::SERVER_PROTOCOL => 'HTTP/1.1',
        Rack::RACK_INPUT => Rack::RewindableInput.new(client),
        Rack::RACK_ERRORS => $stderr,
        Rack::QUERY_STRING => '',
        Rack::RACK_URL_SCHEME => 'http'
      }
      status, headers, body = @app.call(env)

      client.puts "HTTP/1.1 #{status} #{Rack::Utils::HTTP_STATUS_CODES[status]}"
      headers.each do |key, value|
        client.puts "#{key}: #{value}"
      end
      client.puts
      body.each do |chunk|
        client.write chunk
      end
      @logger.info "GET #{path} => #{status}"
    end
  end
end

class ForkServer
  def self.run(app, **options)
    new(app, options).start
  end

  def initialize(app, options)
    @app = app
    @options = options
    @logger = Logger.new($stdout)
  end

  def start
    @logger.info 'ForkServer starting...'
    server = TCPServer.new(@options[:Port].to_i)

    loop do
      client = server.accept
      request_line = client.gets&.chomp
      # リクエストラインの解析
      %r{^GET (?<path>.+) HTTP/1.1$}.match(request_line)
      path = Regexp.last_match(:path)

      fork do
        env = {
          Rack::REQUEST_METHOD => 'GET',
          Rack::SCRIPT_NAME => '',
          Rack::PATH_INFO => path,
          Rack::SERVER_NAME => @options[:Host],
          Rack::SERVER_PORT => @options[:Port].to_s,
          Rack::SERVER_PROTOCOL => 'HTTP/1.1',
          Rack::RACK_INPUT => Rack::RewindableInput.new(client),
          Rack::RACK_ERRORS => $stderr,
          Rack::QUERY_STRING => '',
          Rack::RACK_URL_SCHEME => 'http'
        }
        status, headers, body = @app.call(env)
        client.puts "HTTP/1.1 #{status} #{Rack::Utils::HTTP_STATUS_CODES[status]}"
        headers.each do |key, value|
          client.puts "#{key}: #{value}"
        end
        client.puts
        body.each do |chunk|
          client.write chunk
        end
        @logger.info "GET #{path} => #{status}"
      end
      client.close
    end
  end
end

Rackup::Handler.register 'simple_server', SimpleServer
Rackup::Handler.register 'fork_server', ForkServer

run App.new
