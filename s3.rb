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
require 'highline/import'
require 'encrypted_strings'

# End of require. Start code

class HTTParty::Response
  def ok? ; true end
end

def get_secret(prompt=secret_msg)
	ask(prompt) {|q| q.echo = false}
end

def get_normal(prompt=normal_msg)
	ask(prompt) {|q| q.echo = true}
end

# Init options hash to nil
options = {}
# Use SSL is false default
options[:ssl] = false
# Upload to Imgur is false by default
options[:imgur] = false
# Upload to Cloudapp is false by default
options[:cl] = false

s3_config_file = "#{ENV['HOME']}/.s3"

if !File.exist?(s3_config_file)
	puts "Looks like you need to setup your S3 credentials. "
	s3AccessKey = get_secret("\n Enter your Access Key ID: ")
	s3SecretKey = get_secret("\n Enter your Secret Key:  ")
	s3BucketName = get_normal("\n Enter your Bucket name: ")
	config_file = File.new(s3_config_file, "w")
	config_file.puts(s3AccessKey)
	config_file.puts(s3SecretKey)
	config_file.puts(s3BucketName)
	config_file.close()
end

def s3upload(file,ssl)
	s3_config_file = "#{ENV['HOME']}/.s3" 
	accesskey,secretkey,$bucket = File.read(s3_config_file).split("\n")
	AWS::S3::Base.establish_connection!(
		:access_key_id     => accesskey,
		:secret_access_key => secretkey
	);

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
	cl_config_file = "#{ENV['HOME']}/.cloudapp"
	if !File.exist?(cl_config_file)
		puts "Looks like you need to setup your Cloudapp credentials. "
		clEmail = get_normal("\n Enter your email address: ")
		clPassword = get_secret("\n Enter your password:  ")
		config_file = File.new(cl_config_file, "w")
		config_file.puts(clEmail)
		config_file.puts(clPassword.encrypt(:symmetric, :password => 'my_secret_key'))
		config_file.close()
	end
	email,password = File.read(cl_config_file).split("\n")
	password = password.decrypt(:symmetric, :password => 'my_secret_key')
	puts "Connecting to CloudApp..."
	CloudApp.authenticate(email,password)
	url = CloudApp::Item.create(:upload, {:file => file}).url
	return url
end

def getimgurauth()
	imgur_config_file = "#{ENV['HOME']}/.imgur"
	if !File.exist?(imgur_config_file)
		puts "Looks like you need to setup your Imgur credentials. "
		imgurAPIKey = get_normal("\n Enter your Imgur API Key: ")
		config_file = File.new(imgur_config_file, "w")
		config_file.puts(imgurAPIKey)
		config_file.close()
	end
	imgurFileHandler = File.open(imgur_config_file,"rb")
	return imgurFileHandler.read
end

def imgur(key, file_path)
  url = "http://imgur.com/api/upload.json"
  data = {
	:key     => key, 
	:image 	 => File.open(file_path)
  }
  response = RestClient.post(url, data)
  return JSON.parse(response.body)["rsp"]["image"]["original_image"]  
end

def imgurupload(file)
	imgurauth = getimgurauth()			
	imgurresult = imgur(imgurauth, file)
	return imgurresult
end

def sendemail(recipients,url)
	g_config_file = "#{ENV['HOME']}/.gmail"
	if !File.exist?(g_config_file)
		puts "Looks like you need to setup your GMail credentials. "
		gEmail = get_normal("\n Enter your email address: ")
		gPassword = get_secret("\n Enter your password:  ")
		config_file = File.new(g_config_file, "w")
		config_file.puts(gEmail)
		config_file.puts(gPassword.encrypt(:symmetric, :password => 'my_secret_key'))
		config_file.close()
	end
  
	gusername,gpassword = File.read(g_config_file).split("\n")
	gpassword = gpassword.decrypt(:symmetric, :password => 'my_secret_key')

	Gmail.new(gusername, gpassword) do |gmail|
		gmail.deliver do
			recipients.each do |recipient|
				to recipient
				subject "Here's the file you requested!"
				html_part do
					body "Click the link below to view/download the file: \n" + url
				end
			end
		end
	end
end


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

	opt.on("-e","--email EMAIL1,EMAIL2",Array,"which e-mail address you want to send the link of the uploaded file to") do |email|
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