require 'ec2/helper'
require 'ec2/security_group'
require 'ec2/subnet'

module Ec2
  class QueryApi

    include Helper

    def initialize(vpc_id: nil)
      @vpc_id = vpc_id
    end

    def security_group(name)
      security_group = SecurityGroup.new(name, vpc_id: @vpc_id)
      sg_cache[name] ||= security_group.id!
    end

    def subnet(name)
      subnet = Subnet.new(name, vpc_id: @vpc_id)
      subnet_cache[name] ||= subnet.id!
    end

    private

    def sg_cache
      @sg_cache ||= {}
    end

    def subnet_cache
      @subnet_cache ||= {}
    end

  end
end
