require 'sinatra/base'
require_relative 'upnp/upnp.rb'

class Service < Sinatra::Base
  configure do
    set :views, lambda { File.join(File.dirname(caller[0].split(':').first), "views") }
  end

  def self.decendants
    ObjectSpace.each_object(Class) .select { |klass|
      klass < self
    }
  end
end

Dir[File.join(File.dirname(__FILE__),"services/*/*.rb")].each { |f|
  require_relative f 
}
