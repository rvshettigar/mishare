#!/usr/bin/env ruby
# 
# s3-rb
#
# Command-line interface for Amazon S3 using AWS Ruby Gem (http://amazon.rubyforge.org/)
# Also, options for Cloudapp and Imgur.
#
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
# => Upload file.txt to cloudapp and email it to john@doe.com
#   s3 email -f file.txt -e john@doe.com -c
#
# => Upload pic.png to Imgur and email it to john@doe.com
#   s3 email -f pic.png -e john@doe.com -i
# 
# For complete documentation and license, see http://code.hardikr.com/s3-rb
# 

require 'rubygems'
require 'json'
require 'optparse'
begin
  require 'aws/s3'
rescue LoadError
  puts "You need to install S3 Ruby gem: \ngem install aws-s3"
  exit!(1)
end
begin
  require 'gmail'
rescue LoadError
  puts "You need to install ruby-gmail gem: \ngem install ruby-gmail"
  exit!(1)
end
begin
	require 'rest_client'
rescue LoadError
	puts "You need to install rest-client gem: \n gem install rest-client"
	exit!(1)
end
begin
	require 'cloudapp_api'
rescue LoadError
	puts "You need to install cloudapp_api gem: \ngem install cloudapp_api"
	exit!(1)
end

# End of require. Start code

class HTTParty::Response
  def ok? ; true end
end

# Init options hash to nil
options = {}
# Use SSL is false default
options[:ssl] = false
# Upload to Imgur is false by default
options[:imgur] = false
# Upload to Cloudapp is false by default
options[:cl] = false

config_file = "#{ENV['HOME']}/.s3"
unless File.exist?(config_file)
	puts "You need to type your Access Key ID, Secret Key and Bucket (one per line) into " + "`~/.s3`"
    exit!(1)
end

def s3upload(file,ssl)
	AWS::S3::S3Object.store(File.basename(file), open(file), $bucket, :access => :public_read) #for now only public
	url = s3url(file,ssl,false)
	puts url
	return url
end

def s3url(file,ssl,time)
	if !time
		return AWS::S3::S3Object.url_for(File.basename(file), $bucket, :use_ssl => ssl)[/[^?]+/]
	else
		return AWS::S3::S3Object.url_for(file, $bucket, :expires_in => time, :use_ssl => ssl)
	end
end

def clupload(file)
	config_file = "#{ENV['HOME']}/.cloudapp"
	unless File.exist?(config_file)
	  puts "You need to type your email and password (one per line) into "+
	       "`~/.cloudapp`"
	  exit!(1)
	end
	email,password = File.read(config_file).split("\n")
	puts "Connecting to CloudApp..."
	CloudApp.authenticate(email,password)
	url = CloudApp::Item.create(:upload, {:file => file}).url
	return url
end

def getimgurauth()
	imgur_config_file = "#{ENV['HOME']}/.imgur"
	unless File.exist?(imgur_config_file)
		puts "You need to type your API Key and Cookie (if you want to upload to your own account) (one per line) into " + "`~/.imgur`"
    	exit!(1)
	end
	imgurapi,imgurcookie = File.read(imgur_config_file).split("\n")
	if(!imgurcookie)
		imguruth = imgurapi
	else
		imgurauth = [imgurapi,imgurcookie]
	end
	return imgurauth
end

def imgur(key, cookie, file_path)
  url = "http://imgur.com/api/upload.json"
  data = {
    :key     => key, 
    :image 	 => File.open(file_path)
  }
  headers = {
    :cookies => {"IMGURSESSION" => cookie}
  }
  response = RestClient.post(url, data, headers)
  return JSON.parse(response.body)["rsp"]["image"]["original_image"]  
end

def imgurupload(file)
	imgurauth = getimgurauth()			
	if imgurauth.kind_of? String # No cookie, so upload to public imgur
		imgurresult = imgur(imgurauth, nil, file)
	else 
		imgurresult = imgur(imgurauth[0], imgurauth[1], options[:file])
	end
	return imgurresult
end

def sendemail(recipient,url)
	gconfig_file = "#{ENV['HOME']}/.gmail"
		unless File.exist?(gconfig_file)
    puts "You need to type your email and password (one per line) into " + "`~/.gmail`"
    exit!(1)
  	end
  
  	gusername,gpassword = File.read(gconfig_file).split("\n")

  	Gmail.new(gusername, gpassword) do |gmail|
    	gmail.deliver do
      		to recipient
      		subject "Here's the file you requested!"
      		html_part do
        		body "Click the link below to view/download the file: \n" + url
      		end
    	end
  	end
end

accesskey,secretkey,$bucket = File.read(config_file).split("\n")

AWS::S3::Base.establish_connection!(
    :access_key_id     => accesskey,
    :secret_access_key => secretkey
);

s3rb = OptionParser.new do |opt|
	opt.banner = "\nUsage: s3 COMMAND [OPTIONS]"
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

  	opt.on("-i","--imgur","Uploads image to imgur instead of s3") do
    	options[:imgur] = true
  	end

  	opt.on("-c","--cl","Upload to cloudapp instead of s3") do
  		options[:cl] = true
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
		if options[:imgur]
			url = imgurupload(options[:file])
		elsif options[:cl]
			url = clupload(options[:file])
		else
			url = s3upload(options[:file],options[:ssl])
		end
		if(!options[:email])
			system("echo '#{url}' | xclip -selection clipboard")
			puts "\n URL copied to clipboard!"
		else
			sendemail(options[:email],url);
		end
	end
when "email"
	if !options[:file] and !options[:email]
		puts "Usage: s3 -e FILE -e EMAIL"
	else
		if options[:cl]
			url = clupload(options[:file])
		elsif options[:imgur]
			imgurauth = getimgurauth()			
			if imgurauth.kind_of? String # No cookie, so upload to public imgur
				url = imgur(imgurauth, nil, options[:file])
			else 
				url = imgur(imgurauth[0], imgurauth[1], options[:file])
			end
		else
			url = s3upload(options[:file],options[:ssl])
		end
		sendemail(options[:email],url);
	end
when "expire"
	if !options[:file]
		puts "Usage: s3 expire -f FILE -t TIME"
	else
		if(!options[:time])
			options[:time] = 3600
		end
		url = s3url(options[:file],options[:ssl],options[:time])
		puts url
		if !options[:email]
			system("echo '#{url}' | xclip -selection c")
			puts "\n URL copied to clipboard!"
		else
			sendemail(options[:email],url);
		end
	end
when "torrent"
	if !options[:file]
		puts "Usage: s3 expire -f FILE"
	else
		result = AWS::S3::S3Object.grant_torrent_access_to(options[:file], $bucket)
		if result
			url = s3url(options[:file],options[:ssl],false)+"?torrent"
			puts url
			if !options[:email]
				system("echo '#{url}' | xclip -selection c")
				puts "\n URL copied to clipboard!"
			else
				sendemail(options[:email],url);
			end
		else
			puts result
		end
	end
else
	puts s3rb
end