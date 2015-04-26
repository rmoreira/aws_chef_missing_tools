#!/usr/bin/env ruby

# How to use it:
# Make sure you have the credentials setup:
# export AWS_ACCESS_KEY_ID='Q1W...'
# export AWS_SECRET_ACCESS_KEY="3E4..."
# export REPO=/path_to/repo
# export HOSTED_ZONE_ID='Q1W2E3R4T5Y6YU'
# export DOMAIN="example.com"

# Run this to see nodes : ruby clean_chef_nodes.rb
# Run this to kill nodes: ruby clean_chef_nodes.rb kill
require 'aws-sdk-v1'
require 'thor'
require 'thread'
require 'thwait'
require 'colorize'
require 'logger'

if ENV['NO_COLOR']
  String.disable_colorization = true
end

THREAD_NUM = 5

unless ENV['REPO']
  puts "ENV['REPO'] = /opt/scripts/ops-tools"
  ENV['REPO'] = "/opt/scripts/ops-tools"
end

unless File.directory? "#{ENV['REPO']}/.chef/"
  puts "mkdir -p #{ENV['REPO']}/.chef"
  `mkdir -p #{ENV['REPO']}/.chef`
end

unless File.exists? "#{ENV['REPO']}/.chef/knife.rb"
  puts "cd #{ENV['REPO']}/.chef/; s3cmd get s3://super_secret_files/knife.rb --skip-existing; s3cmd get s3://super_secret_files/opsuser.pem --skip-existing"
  `cd #{ENV['REPO']}/.chef/; s3cmd get s3://super_secret_files/knife.rb --skip-existing; s3cmd get s3://super_secret_files/opsuser.pem --skip-existing`
end

regions = ['us-east-1', 'us-west-1', 'us-west-2', 'eu-west-1']
all_instances = []
all_descriptions = []
regions.each do |region|
  ec2_client = AWS::EC2::Client.new({:region => region})
  description = ec2_client.describe_instances
  all_descriptions << description
  instances = description[:instance_index].keys
  all_instances << instances
end
all_instances.flatten!

a = `knife search "name:*" -a ec2.instance_id -c #{ENV['REPO']}/.chef/knife.rb`
b = a.strip.split("\n").select{|x| x =~ /chef_node_name|i-\w\w\w\w\w\w\w\w|instance_id/} #modify REGEX to match your servers
size = b.size
index = 0
arr = []
while index + 1 < size
  first = b[index].gsub(':','')
  if first =~ /instance_id/
    index += 1
    next
  end
  second = b[index+1].split(' ')[1]
  second = "NO_IP_ADDRESS" if second.nil?
  arr << [first, second]
  index += 2
end

good = []
bad = []
kill_these_servers = []
arr.each do |server|
  is_running = false
  is_in_aws = all_descriptions.select{|d| d[:reservation_index][server[1]].class.to_s == "Hash" }.first
  unless is_in_aws.nil?
    is_running = is_in_aws[:reservation_index][server[1]][:instances_set].select{|x| x[:instance_id] == server[1]}.first[:instance_state][:name] == "running" rescue binding.pry
  end
  result = (all_instances.include?(server[1]) and is_running)
  if result
    good << "#{server[0].light_blue} => #{server[1].green}"
  else
    bad << "#{server[0].yellow} => #{server[1].red}"
    kill_these_servers << server[0]
  end
end

dead_server_size = kill_these_servers.size
kill_these_servers.sort!

puts "#{good.size} GOOD SERVERS".green
puts "-------------".green
puts good.sort
puts "------------- #{good.size} GOOD SERVERS".green
puts "#{bad.size} BAD SERVERS".red
puts "-------------".red
puts bad.sort
puts "------------- #{bad.size} BAD SERVERS".red


if ARGV[0] == "kill"
  if dead_server_size < THREAD_NUM
    THREAD_NUM = dead_server_size
  end

  hosted_zone_id = ENV['HOSTED_ZONE_ID']
  rrsets = AWS::Route53::HostedZone.new(hosted_zone_id).rrsets
  count = 0
  while count < dead_server_size
    for i in (0..THREAD_NUM-1)
      unless kill_these_servers[count+i].nil?
          output = []
          rrset = rrsets["#{kill_these_servers[count+i]}.#{ENV['DOMAIN']}.", "A"]
          if rrset.exists?
            rrset.delete
            output << "#{kill_these_servers[count+i]} EXISTS".green
          else
            output << "#{kill_these_servers[count+i]} GHOST".light_red
          end
          `knife node delete #{kill_these_servers[count+i]} -c #{ENV['REPO']}/.chef/knife.rb -y`
          `knife client delete #{kill_these_servers[count+i]} -c #{ENV['REPO']}/.chef/knife.rb -y`
          output << "knife node delete #{kill_these_servers[count+i]} -c #{ENV['REPO']}/.chef/knife.rb -y".yellow
          output << "knife client delete #{kill_these_servers[count+i]} -c #{ENV['REPO']}/.chef/knife.rb -y".light_blue
          puts output
      end
    end
    puts "--"
    count += THREAD_NUM #for future multi-thread use.
  end
end
