xml.instruct!
xml.tag! 's:Envelope', 
  's:encodingStyle' => 'http://schemas.xmlsoap.org/soap/encoding/',
  'xmlns:s' => 'http://schemas.xmlsoap.org/soap/envelope/' do
  xml.tag! 's:Body' do
    xml.tag! "u:#{action}Response", 'xmlns:u' => "#{namespace}" do
      params.each do |key, value|
        xml.tag!(key, value)
      end
    end
  end
end
