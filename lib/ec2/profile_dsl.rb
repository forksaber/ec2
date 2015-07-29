require 'yaml'
require 'ec2/logger'
require 'ec2/helper'
require 'ec2/profile'
require 'set'

module Ec2
  class ProfileDsl

    include Logger
    include Helper

    attr_reader :api

    def initialize(file, api:)
      @file = file
      @profiles = {}
      @api = api
      @templates = {}
      @availability_zones = ["a", "b"]
      @required = Set.new
    end

    def use(*templates)
      templates.each do |t|
        t = t.to_s
        mprofile(t, template: t){}
      end
    end

    def template(name, &block)
      profile = Profile.new(api: api)
      profile.extends(@base_profile) if @base_profile
      profile.create(transform: false, &block)
      @templates[name] = profile.data
      @templates[name].freeze
    end

    def mprofile(name, template: nil, &block)
      data = @templates.fetch template if template
      @availability_zones.each do |az|
        profile = Profile.new(data: data, api: api)
        profile.extends(@base_profile) if @base_profile
        profile.subnet("#{@base_subnet}-#{az}")
        profile.create &block
        profile_name = "#{name}-#{az}"
        profile.data.freeze
        @profiles[profile_name] = profile.data
      end
    end

    def profile(name, template: nil, &block)
      data = @templates.fetch template if template
      profile = Profile.new(data: data, api: api)
      profile.extends(@base_profile) if @base_profile
      profile.create &block
      profile.data.freeze
      @profiles[name] = profile.data
    end

    def base_profile(name)
      @base_profile = name
    end

    def base_subnet(name)
      @base_subnet = name
    end

    def availability_zones(*zones)
      @availability_zones = zones
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

    def import(path)
      abs_path = File.realpath path
      return if @required.include? abs_path
      instance_eval((File.read abs_path), abs_path)
      @required << abs_path
    end

  end
end
