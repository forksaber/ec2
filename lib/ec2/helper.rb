require 'ec2/error'

module Ec2
  module Helper
    def error(msg)
      raise ::Ec2::Error, msg
    end 
  end
end
