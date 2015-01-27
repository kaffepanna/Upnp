require 'sinatra/base'
require 'sinatra/soap'
require_relative 'soap'

class Service < Sinatra::Base
  def self.decendants
    ObjectSpace.each_object(Class) .select { |klass|
      klass < self
    }
  end
end

Dir["services/*.rb"].each { |f| require_relative f }
