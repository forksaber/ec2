require 'ec2/lock'
require 'ec2/resources'
require 'ec2/config'

module Ec2
  module Cli
    class Resources
    
      def initialize(argv)
        @argv = argv
      end

      def run
        lock.acquire
        opts.parse!(@argv)
        init_aws
        @argv.each do |file|
          resources = ::Ec2::Resources.new(file)
          resources.apply
        end
      end

      def lock
        @lock ||= ::Ec2::Lock.new
      end


      def init_aws
        credentials = Aws::Credentials.new(config[:aws_key], config[:aws_secret])
        Aws.config[:credentials] = credentials
        Aws.config[:region] = config[:region]
      end

      def config
        @config ||= ::Ec2::Config.new("ec2.conf").config
      end

      def opts
        OptionParser.new do |opts|

          opts.banner = "Usage: ec2 resources [options] [target]"
    
          opts.on("-f", "--file FILE", "Specify hosts file") do |f|
            salt.hosts_file = f
          end
          
          opts.on("-h", "--help", "Help") do
            puts opts
            exit
          end
        end
      end

    end
  end
end
