require 'yaml'
require 'ec2/logger'
require 'ec2/helper'
require 'json'

module Ec2
  class Profile

    include Logger
    include Helper

    attr_reader :api, :data

    def initialize(api: nil, data: nil)
      @data = deep_copy(data) || {}
      @api = api
      init_network
    end

    def create(transform: true, &block)
      instance_eval &block
      transform_name_to_id if transform
    end

    def init_network
      return if @data['network_interfaces'].is_a? Array
      @data['network_interfaces'] = [
        {
          "DeviceIndex" => 0,
          "AssociatePublicIpAddress" => true,
          "SecurityGroupId" => []
         }
      ]
    end

    def extends(value)
      @data.store "extends", value
    end

    def size(value)
      @data.store "size", value
    end
    
    def security_group(name, interface: 0)
      @data["network_interfaces"][interface]["SecurityGroupId"] << name
    end

    def subnet(name, interface: 0)
      @data["network_interfaces"][interface]["SubnetId"] = name
    end

    def security_groups(*names, interface: 0)
      names.each { |name| security_group name, interface: interface }
    end

    private

    def deep_copy(hash)
      return nil if not hash.is_a? Hash
      Marshal.load(Marshal.dump hash)
    end


    def transform_name_to_id
      @data["network_interfaces"].each do |n|
        n["SubnetId"] = api.subnet(n["SubnetId"])
        security_groups = n["SecurityGroupId"]

        security_groups.each_with_index do |name, i|
          logger.debug "resolving security_group #{name}"
          security_groups[i] = api.security_group(name)
        end
      end
    end
  end
end
