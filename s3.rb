#!/usr/bin/env ruby
# 
# s3-rb
#
# Command-line interface for Amazon S3 using AWS Ruby Gem (http://amazon.rubyforge.org/)
# Example:
#
# => Upload file.txt
# 	s3 ul -f file.txt
#
# => Upload file.txt and email it's link to john@doe.com
# 	s3 email -f file.txt -e john@doe.com
#
# => Generate public torrent URL for file.txt
#   s3 torrent -f file.txt
#
# => Generate public authenticated URL that expires after 180 seconds
#   s3 expire -f file.txt -t 180
# 
# For complete documentation and license, see http://code.hardikr.com/s3-rb
# 

require 'rubygems'
begin
  require 'aws/s3'
rescue LoadError
  puts "You need to install S3 Ruby gem: gem install aws-s3"
  exit!(1)
end
begin
  require 'gmail'
rescue LoadError
  puts "You need to install ruby-gmail Gem: gem install ruby-gmail"
  exit!(1)
end
require 'optparse'

options = {}
options[:ssl] = false

config_file = "#{ENV['HOME']}/.s3"
unless File.exist?(config_file)
	puts "You need to type your Access Key ID, Secret Key and Bucket (one per line) into " + "`~/.s3`"
    exit!(1)
end

accesskey,secretkey,$bucket = File.read(config_file).split("\n")

AWS::S3::Base.establish_connection!(
    :access_key_id     => accesskey,
    :secret_access_key => secretkey
);

s3rb = OptionParser.new do |opt|
	opt.banner = "Usage: s3rb COMMAND [OPTIONS]"
	opt.separator  ""
	opt.separator  "COMMANDS"
	opt.separator  "     ul:     Uploads a file to an S3 bucket. "
	opt.separator  "          	 USAGE: s3 ul -f FILE"
	opt.separator  "     email:  Uploads a file to an S3 Bucket and then E-mails it."
	opt.separator  "          	 USAGE: s3 email -f FILE -e EMAIL"
	opt.separator  "     expire: Generate expiring link to a file with time in seconds. Time is optional, and will default to 3600 seconds."
	opt.separator  "          	 USAGE: s3 expire -f FILE -t TIME"
	opt.separator  "     torrent: Generate a public torrent for a specified file."
	opt.separator  "          	 USAGE: s3 expire -f FILE"
		

	opt.separator  "Options"

	opt.on("-f","--file FILE","which file you want to upload") do |file|
    	options[:file] = file
  	end

	opt.on("-e","--email EMAIL","which e-mail address you want to send the link of the uploaded file to") do |email|
    	options[:email] = email
  	end
  	
  	opt.on("-t","--time TIME","Time(in secons) in which file expires. Defaults to 60 minutes") do |time|
    	options[:time] = time
  	end
	
	opt.on("-s","--ssl","Use SSL (returns https URL)") do
    	options[:ssl] = true
  	end

	opt.on("-h","--help","help") do
    	puts s3rb
  	end
end

s3rb.parse!

case ARGV[0]
when "ul"
	if !options[:file]
		puts "Usage: s3 -f FILE"
	else
		AWS::S3::S3Object.store(File.basename(options[:file]), open(options[:file]), $bucket, :access => :public_read) #for now only public
		url = AWS::S3::S3Object.url_for(File.basename(options[:file]), $bucket, :use_ssl => options[:ssl])[/[^?]+/]
		puts url
		system("echo #{url} | xclip -selection clipboard")
		puts "\n URL copied to clipboard!"
	end
when "email"
	if !options[:file] and !options[:email]
		puts "Usage: s3 -e FILE -e EMAIL"
	else
		AWS::S3::S3Object.store(File.basename(options[:file]), open(options[:file]), $bucket, :access => :public_read) #for now only public
		url = AWS::S3::S3Object.url_for(File.basename(options[:file]), $bucket, :use_ssl => options[:ssl])[/[^?]+/]
		gconfig_file = "#{ENV['HOME']}/.gmail"
			unless File.exist?(gconfig_file)
	    puts "You need to type your email and password (one per line) into " + "`~/.gmail`"
	    exit!(1)
	  	end
	  
	  	gusername,gpassword = File.read(gconfig_file).split("\n")

	  	Gmail.new(gusername, gpassword) do |gmail|
	    	gmail.deliver do
	      		to options[:email]
	      		subject "Here's the file you requested!"
	      		html_part do
	        		body "Click the link below to view/download the file: \n" + url
	      		end
	    	end
	  	end
	end
when "expire"
	if !options[:file]
		puts "Usage: s3 expire -f FILE -t TIME"
	else
		if(!options[:time])
			options[:time] = 3600
		end
		url = AWS::S3::S3Object.url_for(options[:file], $bucket, :expires_in => options[:time], :use_ssl => options[:ssl])
		puts url
		system("echo #{url} | xclip -selection clipboard")
		puts "\n URL copied to clipboard!"
	end
when "torrent"
	if !options[:file]
		puts "Usage: s3 expire -f FILE"
	else
		result = AWS::S3::S3Object.grant_torrent_access_to(options[:file], $bucket)
		if result
			url = (AWS::S3::S3Object.url_for(File.basename(options[:file]), $bucket)[/[^?]+/])+"?torrent"
			puts url
			system("echo #{url} | xclip -selection clipboard")
			puts "\n URL copied to clipboard!"
		else
			puts result
		end
	end
else
	puts s3rb
end