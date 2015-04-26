#!/usr/bin/env ruby

require 'aws-sdk-v1'
require 'thor'
require 'thread'
require 'thwait'
require 'colorize'
require 'logger'
AWS.config(:logger => Logger.new($stdout)) if ARGV.include? "--debug" or ARGV.include? "-d"
###
# Examples:
# ./elb.rb list
# ./elb.rb list -r demo
# ./elb.rb list -r "^dev-"
# ./elb.rb details -r "^dev-"
# ./elb remove -n dumm -i i-b4b2b451
# ./elb add -n dumm -i i-b4344451
# ./elb refresh -n dumm
# ./elb refresh --name dumm
###

time0 = Time.now
$elbs = AWS.memoize{ AWS.elb.load_balancers }
$name = []


class CLI < Thor
  option :debug, :required => false, :aliases => :d
  option :regex, :required => false, :aliases => :r
  desc "list", "list load balancers"
  def list
    $names = $elbs.map(&:name)
    unless options[:regex]
      puts $names.sort
    else
      tmp = $elbs.select{|x| x.name.match(options[:regex])}.map(&:name)
      puts tmp.sort
    end
  end

  option :debug, :required => false, :aliases => :d
  option :regex, :required => false, :aliases => :r
  desc "details", "details load balancers"
  def details
    tmp = $elbs.select{|x| x.name.match(options[:regex])}
    tmp.each {|x| threads = []; output = ["#{"Load Balancer Name".yellow.underline}:\t#{x.name.light_blue}"]; output << "#{"DNS Name / A Record".green.underline}:\t#{x.dns_name.light_red}"; output << "Instance ID\t-\tIp Address\t-\tState\t\t-\tInstance Name\t\t\t\t\t-\tDescription".underline; x.instances.health.map{|y| 
      threads << Thread.new {
        output << "#{y.instance.id.yellow}\t-\t#{y.instance.private_ip_address.light_blue || y.instance.ip_address.light_blue}\t-\t#{y[:state]=="InService" ? y[:state].green : y[:state].yellow}\t-\t#{y.instance.tags["Name"] ? y.instance.tags["Name"].red : "Nameless".light_red }\t\t-\t#{y[:description]}"
        }
      }
    ThreadsWait.all_waits(*threads)
    
    puts output
    puts
    }
  end

  option :debug, :required => false, :aliases => :d
  option :name, :required => true, :aliases => :n
  option :instances, :required => true, :aliases => :i, :type => :array
  desc "add", "add instances to a load balancer"
  def add
    tmp = $elbs[options[:name]]
    puts "Before:".yellow
    puts "#{tmp.instances.map(&:id)}".light_blue
    puts
    tmp.instances.add(options[:instances]) if options[:instances]
    puts "After:".yellow
    puts "#{tmp.instances.map(&:id)}".light_red
  end

  option :debug, :required => false, :aliases => :d
  option :name, :required => true, :aliases => :n
  option :instances, :required => true, :aliases => :i, :type => :array
  desc "remove", "remove instances from a load balancer"
  def remove
    tmp = $elbs[options[:name]]
    puts "Before:".yellow
    puts "#{tmp.instances.map(&:id)}".light_blue
    puts
    tmp.instances.remove(options[:instances]) if options[:instances]
    puts "After:".yellow
    puts "#{tmp.instances.map(&:id)}".light_red
  end

  option :debug, :required => false, :aliases => :d
  option :name, :required => true, :aliases => :n
  desc "refresh", "refresh instances in a load balancer"
  def refresh
    tmp = $elbs[options[:name]]
    ids = tmp.instances.map(&:id)
    puts "Before:".yellow
    puts "#{ids}".light_blue
    puts
    tmp.instances.remove(ids) unless ids.empty?
    puts "After:".yellow
    puts "#{tmp.instances.map(&:id)}".light_red
    tmp.instances.add(ids) unless ids.empty?
    puts "Again:".yellow
    puts "#{tmp.instances.map(&:id)}".green
  end
end

CLI.start
time1 = Time.now
puts "execution time: #{time1 - time0} seconds"
