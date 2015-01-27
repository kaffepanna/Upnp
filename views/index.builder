xml.instruct!
xml.root xmlns: 'urn:schemas-upnp-org:device-1-0' do
  xml.specVersion do
    xml.major '1'
    xml.minor '0'
  end
  xml.device do
    xml.deviceType 'urn:schemas-upnp-org:device:MediaServer:1'
    xml.friendlyName serverName
    xml.manufacturer manufacturer[:name]
    xml.manufacturerURL manufacturer[:url]
    xml.modelName model[:name]
    xml.modelDescription model[:description]
    xml.modelNumber model[:number]
    xml.modelURL model[:url]
    xml.serialNumber '12314232342342'
    xml.presentationURL '/'
    xml.UDN "uuid:#{uuid}"
    xml.serviceList do
      services.each do |service|
        xml.service do
          xml.serviceType "urn:schemas-upnp-org:service:#{service[:type]}:1"
          xml.serviceId "urn:upnp-org:serviceId:#{service[:type]}"
          xml.controlURL "/#{service[:type]}/ctl"
          xml.eventSubURL "/#{service[:type]}/event"
          xml.SCPDURL "/#{service[:type]}"
        end
      end
    end
  end
end

