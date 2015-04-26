#!/usr/bin/env ruby

# How to use it:
# Make sure you have the credentials setup:
# export AWS_ACCESS_KEY_ID='AKI...'
# export AWS_SECRET_ACCESS_KEY="WU..."
#
# Run this to see volumes : ruby clean_ebs_volumes.rb
# Run this to delete volumes: ruby clean_ebs_volumes.rb delete

require 'aws-sdk-v1'
require 'colorize'

if ENV['NO_COLOR']
  String.disable_colorization = true
end

puts
puts "Cleaning up unused EBS Volumes"
puts

regions = ['us-east-1', 'us-west-1', 'us-west-2', 'eu-west-1']
regions.each do |region|
  puts "REGION: #{region}".yellow
  puts "-------------------"
  ec2 = AWS::EC2.new({:region => region})
  describe_volumes = ec2.client.describe_volumes
  all_volumes = describe_volumes.volume_set.select{|x| x[:status] == "available"}
  volume_indeces = all_volumes.map(&:volume_id)
  
  if ARGV[0] == "delete"
    puts "Deleting:".light_red
    volume_indeces.each{|volume_id| puts volume_id.red; ec2.volumes[volume_id].delete}
  else
    puts "Would Be Deleting:".light_blue
    volume_indeces.each{|volume_id| puts volume_id.light_green}
  end
  puts "Nothing".green if volume_indeces.empty?
  puts "-------------------"
  puts
end