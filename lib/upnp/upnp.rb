module Sinatra
  module UpnpSoap
    module DslMethods
      def upnp action, &block
        #define_method(action, block)
        settings.upnp_actions[action] = block
#        upnp_actions[action] = block
      end
    end

    module Helpers
      def parse_request

      end
    end


    def self.registered(app)
      include DslMethods
      app.helpers UpnpSoap::Helpers
      app.set :control, '/ctl' unless defined?(app.settings.control)
      app.set :upnp_views, File.join(File.dirname(__FILE__), 'views')
      app.set :upnp_actions, {}

      app.post(app.settings.control) do
        content_type 'text/xml'
        action = env['HTTP_SOAPACTION'].to_s.gsub('"', '').split('#').last.to_sym
        namespace = env['HTTP_SOAPACTION'].to_s.gsub('"', '').split('#').first
        input = env['rack.input'].read
        env['rack.input'].rewind
        nori = Nori.new(strip_namespaces: true, advanced_typecasting: true,
                        convert_tags_to: lambda { |tag| tag.to_sym })

        soap = nori.parse(input)[:Envelope][:Body][action]
        response = self.instance_exec(soap, &settings.upnp_actions[action])
        
        builder :response, locals: {namespace: namespace, action: action.to_s, params: response}, views: settings.upnp_views

      end
      
      Delegator.delegate :upnp
    end
  end
  
  register UpnpSoap
end
