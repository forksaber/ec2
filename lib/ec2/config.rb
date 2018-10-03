require 'ec2/helper'
module Ec2
  class Config

    include Helper

    def initialize(config_path)
      @config_path = config_path
    end

    def config
      return @config if @config
      @config = {
        region: "ap-southeast-1",
        use_iam: true
      }
      read_config
      return @config
    end

    private

    def region(region)
      set :region, region
    end

    def vpc_id(vpc)
      set :vpc_id, vpc
    end

    def aws_key(aws_key)
      set :aws_key, aws_key
      set :use_iam, false
    end

    def aws_secret(aws_secret)
      set :aws_secret, aws_secret
      set :use_iam, false
    end

    def set(key, value)
      @config.store key, value
    end

    def read_config
      read("#{Dir.home}/.ec2.rb", required: false)
      read(@config_path, required: false)
    end

    def read(file, required: true)
      if not File.readable? file
        raise error "config: #{file} not readable" if required
        return
      end
      instance_eval(File.read(file), file)
    rescue NoMethodError => e
      error "invalid option used in config: #{e.name}"
    end
  
  end
end
