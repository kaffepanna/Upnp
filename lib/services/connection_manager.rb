
class ConnectionManager < Service
  configure do
    set :threaded, false
    set :endpoint, '/ctl'
  end

  register Sinatra::Soap

  get '/' do
    content_type 'application/xml'
    puts "Reading ConnectionManager"
    File.read(File.join(settings.views, "ConnectionManager1.xml"))
  end

  soap :GetProtocolInfo, out: { GetProtocolInfoResponse: { Source: :string, Sink: :string }} do
    puts "Got GetProtocolInfo #{params.inspect}"
    { Source: "http-get:*:image/jpeg", Sink: ""}
  end
end

