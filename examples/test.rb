require 'pry'
lib = File.expand_path(__dir__ + '/../lib')
$LOAD_PATH.unshift(lib) 

require 'aws-sdk'
require 'ec2/config'
require 'ec2/query_api'
require 'ec2/profile_dsl'

config = Ec2::Config.new(".ec2.rb").config
credentials = Aws::Credentials.new(config[:aws_key], config[:aws_secret])
Aws.config[:credentials] = credentials
Aws.config[:region] = config[:region]

api = Ec2::QueryApi.new(vpc_id: config[:vpc_id])

x = Ec2::ProfileDsl.new("profiles.rb", api: api)
pry
