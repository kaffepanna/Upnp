require 'sinatra/base'
require_relative 'services'


class Device < Sinatra::Base
  configure do
    set :threaded, false
    set :endpoint, '/ctl'
    set :uuid, SecureRandom.uuid
  end

  before '/' do
    puts "Serving /"
  end

  get '/' do
    content_type 'application/xml'
    locals = {}
    locals[:serverName] = "Kaffe MediaServer"
    locals[:manufacturer] = {
      name: "randomerserver.se",
      url: "http://randomserver.se",
    }
    locals[:model] = {
      name: 'randomserver media server',
      description: ' media serverver',
      number: '0.0.1',
      url: 'http://randomserver.se'
    }
    locals[:uuid] = settings.uuid
    locals[:services] = Service.decendants.map {|service| 
      { type: service.to_s } 
    }
    builder :index, locals: locals
  end
end



