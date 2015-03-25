require 'ec2/helper'
require 'ec2/logger'
module Ec2
  class Subnet

    include Helper
    include Logger

    def initialize(name, vpc_id: nil)
      error "vpc_id not specified for subnet" if not vpc_id
      @vpc_id = vpc_id.to_s
      @name = name.to_s
    end

    def id!
      load_id if not @id
      error "specified subnet #{@name} doesn't exist in vpc #{@vpc_id}" if not exists?
      @id
    end

    def created(&block)
      instance_eval &block
      load_id using_cidr: true
      if exists?
        tag if not tagged?
        verify
      else
        create
        tag
      end
    end

    private

    def subnet
      @subnet ||= ::Aws::EC2::Subnet.new(@id)
    end

    def create
      resp = ec2.create_subnet(
        vpc_id: @vpc_id,
        cidr_block: @cidr,
        availability_zone: @availability_zone
      )
      @id = resp.subnet.subnet_id
      logger.info "(#{@name}) created subnet: #{@cidr}" 
    rescue Aws::Errors::ServiceError, ArgumentError
      error "while creating subnet #{@name}"
    end

    def tag
      subnet.create_tags(
        tags: [ { key: "Name", value: @name } ]
      )
      subnet.load
    end

    def tagged?
      subnet.tags.any? { |tag| tag.key == "Name"}
    end

    def verify
      name_tag = subnet.tags.find { |tag| tag.key == "Name" }.value
      error "availability zone mismatch for subnet #{@name}" if subnet.availability_zone != @availability_zone
      error "subnet #{@name} already tagged with another name #{name_tag}" if @name != name_tag
    end

    def cidr(cidr)
      @cidr = cidr
    end

    def availability_zone(availability_zone)
      @availability_zone = availability_zone
    end

    alias_method :az, :availability_zone


    def load_id(using_cidr: false)
      filters = []
      
      if using_cidr
        filters << { name: "cidr", values: [@cidr.to_s] }
      else
        filters << { name: "tag:Name", values: [@name.to_s] }
      end

      filters << { name: "vpc-id", values: [@vpc_id.to_s] }
      result = ec2.describe_subnets(filters: filters)
      error "mulitple subnets found with name #{@name}" if result.subnets.size > 1
      @id = result.subnets.first.subnet_id if result.subnets.size == 1
    end

    def exists?
      @id
    end
 
    def ec2
      @ec2 ||= begin
        @region ? Aws::EC2::Client.new(region: @region) : Aws::EC2::Client.new
      end
    end

  end
end
