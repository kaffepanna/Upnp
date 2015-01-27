require 'sinatra/base'
require 'sinatra/soap'
require_relative 'soap'

class Service < Sinatra::Base
  def self.decendants
    ObjectSpace.each_object(Class) .select { |klass|
      klass < self
    }
  end
end

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
      description: 'Simple media serverver',
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

class ConnectionManager < Service
  configure do
    set :threaded, false
    set :endpoint, '/ctl'
  end

  register Sinatra::Soap

  get '/' do
    content_type 'application/xml'
    puts "Reading ConnectionManager"
    File.read("views/ConnectionManager1.xml")
  end

  soap :GetProtocolInfo, out: { GetProtocolInfoResponse: { Source: :string, Sink: :string }} do
    puts "Got GetProtocolInfo #{params.inspect}"
    { Source: "http-get:*:image/jpeg", Sink: ""}
  end


end


