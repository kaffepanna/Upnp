require 'eventmachine'
require 'ipaddr'
require 'sinatra/base'
require 'sinatra/soap'
require 'thin'
require 'nori'
require_relative 'device'

IP='192.168.1.88'

ROOT_RESPONSE = <<-EOF
HTTP/1.1 200 OK
CACHE-CONTROL: max-age=130
LOCATION: http://#{IP}:8200/
SERVER: 3.2.0-61-generic UPnP/1.0 kaffeMediaServer/0.0.1
EXT:
ST: upnp:rootdevice
USN: uuid:#{Device.settings.uuid}::upnp:rootdevice
Content-Length: 0

EOF

MEDIA_SERVER = <<-EOF
HTTP/1.1 200 OK
CACHE-CONTROL: max-age=130
ST: urn:schemas-upnp-org:device:MediaServer:1
USN: uuid:#{Device.settings.uuid}::urn:schemas-upnp-org:device:MediaServer:1
LOCATION: http://#{IP}:8200/
SERVER: 3.2.0-61-generic UPnP/1.0 kaffeMediaServer/0.0.1
EXT:
Content-Length: 0

EOF

RESPONSES = [ ROOT_RESPONSE, MEDIA_SERVER ]
RESPONSES += Service.decendants.map {|service|
<<-EOF
HTTP/1.1 200 OK
CACHE-CONTROL: max-age=130
ST: urn:schemas-upnp-org:service:#{service.to_s}:1
USN: uuid:#{Device.settings.uuid}::urn:schemas-upnp-org:service:#{service.to_s}:1
LOCATION: http://#{IP}:8200/
SERVER: 3.2.0-61-generic UPnP/1.0 kaffeMediaServer/0.0.1
EXT:
Content-Length: 0

EOF

}

class Client < EventMachine::Connection
  attr_reader :search_request

  def initialize request
      @search_request = request
      puts "Socketsetup"
      set_sock_opt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP,
                   IPAddr.new('239.255.255.250').hton +
                   IPAddr.new('0.0.0.0').hton)
  end

  def peer_info
    peer_bytes = get_peername[2,6].unpack('nC4')
    port = peer_bytes.first.to_i
    ip = peer_bytes[1,4].join('.')
    [ip, port]
  end

  def receive_data data
    return unless data =~ /M-SEARCH/
    ip, port = peer_info
    search_request.push([ip, port])
  end
end


EM.run {
  search_request = EM::Channel.new
  us = EM.open_datagram_socket('0.0.0.0', 1900, Client, search_request)

  search_request.subscribe { |ip, port|
    puts "Responding to #{ip} #{port}"
    #rs = EM.open_datagram_socket('0.0.0.0', port)
    RESPONSES.each do |resp|
      puts resp
      us.send_datagram(resp.split("\n").join("\r\n"), ip, port)
    end
  }
  EM::PeriodicTimer.new(15) do
    #us.send_datagram NOTIFY, '239.255.255.250', 1900
  end

  dispatch = Rack::Builder.app do
    map '/' do
      run Device
    end
    Service.decendants.each do |service|
      map "/#{service.to_s}" do
        run service
      end
    end
  end

  app =Rack::Server.start({
    app: dispatch,
    server: 'thin',
    Host: IP,
    Port: 8200,
    signals: false,
  })
}


