require 'sinatra/base'
require 'sinatra/soap'
require_relative 'soap'

class Service < Sinatra::Base
  configure do
    set :views, File.join(File.dirname(__FILE__), "views")
  end

  def self.decendants
    ObjectSpace.each_object(Class) .select { |klass|
      klass < self
    }
  end
end

Dir[File.join(File.dirname(__FILE__),"services/*.rb")].each { |f| require_relative f }
