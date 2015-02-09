require 'logger'
require 'ec2/custom_logger'
module Ec2
  module Logger
    
    def self.logger
      @logger ||= CustomLogger.new(STDOUT)
    end 

    def self.stderr
      @stderr ||= ::Logger.new(STDERR)
    end 

    def logger
      ::Ec2::Logger.logger
    end 

    def stderr
      ::Ec2::Logger.stderr
    end 

    def debug?
      logger.level == ::Logger::DEBUG
    end

  end 
end
