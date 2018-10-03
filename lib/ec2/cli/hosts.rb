require 'ec2/lock'
require 'ec2/salt_cloud'
require 'ec2/config'

module Ec2
  module Cli
    class Hosts
    
      def initialize(argv)
        @argv = argv
      end

      def run
        lock.acquire
        opts.parse!(@argv)
        salt.config = config
        salt.run
        puts "ran hosts"
      end

      def salt
        @salt ||= ::Ec2::SaltCloud.new
      end

      def lock
        @lock ||= ::Ec2::Lock.new
      end

      def config
        @config ||= ::Ec2::Config.new("ec2.rb").config
      end

      def opts
        OptionParser.new do |opts|

          opts.banner = "Usage: ec2 hosts [options] [target]"
    
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
