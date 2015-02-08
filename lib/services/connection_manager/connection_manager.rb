
class ConnectionManager < Service
  configure do
    set :threaded, false
    set :endpoint, '/ctl'
  end

  register Sinatra::UpnpSoap

  get '/' do
    content_type 'application/xml'
    puts "Reading ConnectionManager"
    File.read(File.join(settings.views, "ConnectionManager1.xml"))
  end

  upnp :GetProtocolInfo do
    { Source: "http-get:*:image/jpeg", Sink: ""}
  end
end

