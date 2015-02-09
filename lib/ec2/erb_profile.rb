require 'ec2/logger'
require 'ec2/helper'
require 'erb'

module Ec2
  class ErbProfile

    include Logger
    include Helper

    attr_accessor :api

    def initialize(file, api: nil)
      @file = file
      @api = api
    end

    def binding
      api.instance_eval { binding }
    end

    def render
      erb = ERB.new(File.read(@file), nil, '-')
      erb.result(binding)
    rescue => e
      error "while rendering erb file #{@file}"
    end

  end
end
