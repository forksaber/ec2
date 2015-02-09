require 'fileutils'
require 'pathname'
require 'aws-sdk'

require 'ec2/query_api'
require 'ec2/profile_dsl'
require 'ec2/erb_profile'
require 'ec2/logger'

module Ec2
  class SaltCloud

    include Logger
    attr_writer :hosts_file
    attr_accessor :config

    def initialize
    end

    def run
      init_working_dir
      copy_providers
      copy_profiles
      copy_master_config
      copy_deploy_scripts
      init_aws
      render_global_profiles
      render_local_profile
      run_salt_cloud
    end

    private

    def init_aws
      credentials = Aws::Credentials.new(config[:aws_key], config[:aws_secret])
      Aws.config[:credentials] = credentials
      Aws.config[:region] = config[:region]
    end

    def api
      @api ||= QueryApi.new(vpc_id: config[:vpc_id])
    end

    def working_dir
      @working_dir ||= ".salt.tmp"
    end

    def hosts_file
      @hosts_file ||= "hosts"
    end 

    def init_working_dir
      FileUtils.rm_r working_dir if File.directory? working_dir
      FileUtils.mkdir_p "#{working_dir}/cloud.profiles.d"
    end

    def copy_providers
      return if not File.directory? "/etc/salt/cloud.providers.d"
      FileUtils.cp_r "/etc/salt/cloud.providers.d", working_dir
    end

    def copy_profiles
      return if not File.directory? "/etc/salt/cloud.profiles.d"
      Dir["/etc/salt/cloud.profiles.d/*.conf"].each do |f|
        path = Pathname.new f
        FileUtils.cp path, "#{working_dir}/cloud.profiles.d/_#{path.basename}"
      end
    end

    def copy_master_config
      FileUtils.cp "/etc/salt/master", working_dir
    end

    def copy_deploy_scripts
      return if not File.directory? "/etc/salt/cloud.deploy.d"
      FileUtils.cp_r "/etc/salt/cloud.deploy.d", working_dir
    end

    def render_global_profiles
      Dir["/etc/salt/cloud.profiles.d/*.erb"].each do |f|
        render(f, prefix: "_")
      end
    end

    def render_local_profile
      local_profile = ["profiles.rb", "profiles.erb"].find { |f| File.readable? f }
      render(local_profile) if local_profile
    end

    def render(path, prefix: nil)
      extname = File.extname path
      name = File.basename(path, extname)
      outfile = "#{working_dir}/cloud.profiles.d/#{prefix}#{name}.conf"
      case extname
      when ".rb"
        profile_dsl = ProfileDsl.new(path, api: api)
        File.open(outfile, "w") { |f| f.write profile_dsl.render }
      when ".erb"
        erb = ErbProfile.new(path, api: api)
        File.open(outfile, "w") { |f| f.write erb.render } 
      end
    end
    
    def run_salt_cloud
      logger.debug "running salt cloud"
      command =  %Q( salt-cloud -m #{hosts_file} -c #{working_dir} )
      command << " -l debug" if logger.trace?
      system command
    end

  end
end
