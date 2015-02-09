require 'ec2/security_group'
require 'ec2/subnet'
module Ec2
  class Resources


    def initialize(file)
      @file = file
    end

    def vpc_id(vpc_id)
      @vpc_id = vpc_id
    end

    def security_group(name, &block)
      sg = SecurityGroup.new(name, vpc_id: @vpc_id)
      sg.created &block
    end

    def subnet(name, &block)
      subnet = Subnet.new(name, vpc_id: @vpc_id)
      subnet.created &block
    end


    def apply
      instance_eval(File.read(@file), @file)
    end

  end
end
