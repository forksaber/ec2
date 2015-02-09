require 'ec2/helper'
require 'ec2/logger'
require 'aws-sdk'
require 'set'

module Ec2
  class SecurityGroup

    include Helper
    include Logger
    attr_reader :desired_permissions

    def initialize(name, vpc_id: nil)
      error "vpc_id not specified for security group" if not vpc_id
      @vpc_id = vpc_id.to_s
      @name = name
      @dry_run = false
    end

    def id
      return @id unless @id.nil?
      @id = load_id
    end

    def description(description)
      @description = description
    end

    def id!
      error "specified security_group #{@name} doesn't exist in vpc #{@vpc_id}" if not exists?
      id
    end

    def created(&block)
      clear_vars
      instance_eval &block
      create if not exists?
      sync
    end

    private

    def sg
      @sg ||= ::Aws::EC2::SecurityGroup.new(id)
    end

    def create
      resp = ec2.create_security_group(
        group_name: @name, 
        description: @description,
        vpc_id: @vpc_id
      )
      @id = resp.group_id
      logger.info "(#{@name}) created security group" 
    rescue Aws::Errors::ServiceError, ArgumentError
      error "while creating security_group #{@name}"
    end

    def load_id
      filters = []
      filters << { name: "group-name", values: [@name.to_s] }
      filters << vpc_filter
      result = ec2.describe_security_groups(filters: filters)
      if result.security_groups.size == 1
        return result.security_groups.first.group_id
      else
        return false
      end
    end

    def exists?
      id
    end

    def vpc_filter
      { name: "vpc-id", values: [@vpc_id.to_s] } 
    end

    def outbound(&block)
      @outbound = true
      instance_eval &block 
    ensure
      @outbound = false
    end

    def parse_ports(port)
      if port.is_a? Integer
        return port, port
      elsif port =~ /\A([0-9]+)\z/
        return $1.to_i, $1.to_i
      elsif port =~ /\A([0-9]+)\-([0-9]+)\z/
        return $1.to_i, $2.to_i
      else
        error "invalid port specified #{port}"
      end
    end

    def tcp(port, **args)
      (from_port, to_port) = parse_ports(port)
      rule(ip_protocol: "tcp", from_port: from_port, to_port: to_port, **args)
    end

    def udp(port, **args)
      (from_port, to_port) = parse_ports(port)
      rule(ip_protocol: "udp", from_port: from_port, to_port: to_port, **args)
    end

    def icmp(**args)
      rule(ip_protocol: "icmp", from_port: -1, to_port: -1, **args)
    end

    def rule(ip_protocol: nil, from_port: nil, to_port: nil, cidr_ip: nil)
      options = {
        ip_protocol: ip_protocol,
        from_port: from_port,
        to_port: to_port,
        cidr_ip: cidr_ip
      }
      if not @outbound
        @desired_permissions ||= Set.new
        @desired_permissions << options
      end
    end

    def current_permissions
      @current_permissions ||= begin
        permissions = Set.new 
        sg.ip_permissions.each do |permission|
          rules = permission_to_rules(permission)
          rules.each { |r| permissions << r }
        end
        permissions
      end
    end

    def diff(current, desired)
      to_add = desired - current
      to_remove = current - desired
      s = Struct.new(:to_add, :to_remove)
      s.new(to_add, to_remove)
    end

    def sync
      ingress_diff.to_add.each { |r| authorize_ingress r }
      ingress_diff.to_remove.each { |r| revoke_ingress r }
    end


    def authorize_ingress(rule)
      sg.authorize_ingress rule if not @dry_run
      logger.info "(#{@name}) #{"+".green.bold} allow #{rule[:cidr_ip]} #{rule[:from_port]}-#{rule[:to_port]}"
    rescue Aws::Errors::ServiceError
      error "error authorizing rule #{rule}"
    end

    def revoke_ingress(rule)
      sg.revoke_ingress rule if not @dry_run
      logger.info "(#{@name}) #{"-".red.bold} allow #{rule[:cidr_ip]} #{rule[:from_port]}-#{rule[:to_port]}"
    end

    def ingress_diff
      @ingress_diff ||= diff(current_permissions, desired_permissions)
    end

    def clear_vars
      @desired_permissions = nil
      @current_permissions = nil
      @ingress_diff = nil
    end

    def permission_to_rules(permission)
      rules = Set.new
      permission.ip_ranges.each do |r|
        rule = {
          ip_protocol: permission.ip_protocol,
          from_port: permission.from_port,
          to_port: permission.to_port,
          cidr_ip: r.cidr_ip
        }
        rules << rule
      end
      rules
    end

    def ec2
      @ec2 ||= begin
        if @region
          Aws::EC2::Client.new(region: @region)
        else
          Aws::EC2::Client.new
        end
      end
    end

  end
end
