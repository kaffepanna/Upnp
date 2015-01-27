xml.instruct!
xml.tag! 's:Envelope', 'xmlns:s' => 'http://schemas.xmlsoap.org/soap/envelope/' do
  xml.tag! 's:Body' do
    xml.tag! "u:#{wsdl.action}Response", 'xmlns:u' => "#{wsdl.namespace}" do
      params.each do |key, value|
        xml.tag! key, value
      end
    end
  end
end
