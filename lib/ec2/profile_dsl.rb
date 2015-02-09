require 'yaml'
require 'ec2/logger'
require 'ec2/helper'

module Ec2
  class ProfileDsl

    include Logger
    include Helper

    attr_reader :api

    def initialize(file, api: nil)
      @file = file
      @profiles = {}
      @api = api
    end

    def profile(name, &block)
      current_profile = name.to_s
      @data = {}
      @data["extends"] = @base if @base
      init_network
      yield
      @profiles[current_profile] = @data
    end

    def base(name)
      @base = name
    end

    def extends(value)
      @data.store "extends", value
    end

    def size(value)
      @data.store "size", value
    end
    
    def init_network
      @data['network_interfaces'] = [
        {
          "DeviceIndex" => 0,
          "AssociatePublicIpAddress" => true,
          "SecurityGroupId" => []
         }
      ]
    end
    
    def security_group(group_name)
      group_id = api.security_group(group_name)
      @data["network_interfaces"][0]["SecurityGroupId"] << group_id
    end

    def subnet(subnet_name)
      subnet_id = api.subnet(subnet_name)
      @data["network_interfaces"][0]["SubnetId"] = subnet_id
    end
      
    def render
      if not File.readable? @file
        logger.info "#{@file} not readable"
        return
      end
      instance_eval(File.read(@file), @file)
      YAML.dump @profiles
    rescue NoMethodError => e
      error "invalid option used in profiles config: #{e.name}"
    end

    def vpc_id(vpc_id)
      @vpc_id = vpc_id
    end

  end
end
