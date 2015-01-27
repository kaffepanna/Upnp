module Sinatra
  module Soap
    module HelperMethods
      def call_action_block
        request = Soap::Request.new(env, request, params)
        response = request.execute
        builder :response, locals: {wsdl: response.wsdl, params: response.params}
        rescue Soap::Error => e
          builder :error, locals: {e: e}, :views => self.soap_views
      end
    end

    class Request
      def action
        return orig_params[:action] unless orig_params[:action].nil?
        action = env['HTTP_SOAPACTION'].to_s.gsub('"', '').split('#').last
        puts "Action: #{action}"
        orig_params[:action] = action.to_sym
      end

      def namespace
        namespace = env['HTTP_SOAPACTION'].to_s.gsub('"', '').split('#').first
        puts "Namespace #{namespace}"
        namespace
      end

      def wsdl
        @wsdl = Soap::Wsdl.new(action, namespace)
      end
    end

    class Wsdl
      attr_accessor :namespace

      def initialize(action, namespace=nil)
        data = all[action]
        raise Soap::Error, "Undefined Soap Action" if data.nil?
        @action = action
        @block = data[:block]
        @arguments = data.select {|k,v| k != :block}
        @namespace = namespace
      end
    end
  end
end

