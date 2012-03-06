#!/usr/bin/env ruby
# 
# mishare
#
# Command-line interface for Amazon S3, Cloudapp and Imgur
# You can also use it to email the file to someone (Gmail only)
#
# Example:
#
# => Upload file.txt
# 	mishare ul -f file.txt
#
# => Upload file.txt and email it's link to john@doe.com and jane@doe.com
# 	mishare ul -f file.txt -e john@doe.com jane@doe.com
#
# => Generate public torrent URL for file.txt
#  	mishare torrent -f file.txt
#
# => Generate public authenticated URL that expires after 180 seconds and email it to john@doe.com
#  	mishare expire -f file.txt -t 180 -e john@doe.com
#
# => Upload file.txt to cloudapp and email it to john@doe.com
#  	mishare ul -f file.txt -e john@doe.com -c
#
# => Upload pic.png to Imgur and email it to john@doe.com
#  	mishare ul -f pic.png -e john@doe.com -i
# 
# For complete documentation and licensing information, see http://code.hardikr.com/mishare
# 

require 'rubygems'
require 'json'
require 'optparse'
require 'uri'
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
begin
	require 'dropbox_sdk'
rescue LoadError
	puts "You need to install dropbox-sdk gem: \ngem install dropbox-sdk"
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
#Upload to Dropbox is false by default
options[:db] = false

s3_config_file = "#{ENV['HOME']}/.s3"

if !File.exist?(s3_config_file)
	puts "Looks like you need to setup your S3 credentials. "
	s3AccessKey = get_normal("\n Enter your Access Key ID: ")
	s3SecretKey = get_normal("\n Enter your Secret Key:  ")
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

def db(file_path)
	db_config_file = "#{ENV['HOME']}/.dbconfig"
	db_session_file = "#{ENV['HOME']}/.dbsession"
	if !File.exist?(db_config_file)
		puts "Looks like you need to setup your Imgur credentials. "
		dbappkey = get_normal("\n Enter your Dropbox App Key: ")
		dbsecret = get_normal("\n Enter your Dropbox App Secret: ")
		config_file = File.new(db_config_file, "w")
		config_file.puts(dbappkey)
		config_file.puts(dbsecret)
		config_file.close()
	else 
		dbappkey,dbsecret = File.read(db_config_file).split("\n")
	end

	if !File.exist?(db_session_file)
		puts "Looks like we need to authorize you!"
		session = DropboxSession.new(dbappkey,dbsecret)
		session.get_request_token
		authorize_url = session.get_authorize_url
		puts "AUTHORIZING DROPBOX", authorize_url
		puts "Please visit that website and hit 'Allow', then hit Enter here."
		STDIN.gets

		token = session.get_access_token
		ser = session.serialize()
		File.open(db_session_file,'w') do |file|
		 Marshal.dump(ser, file)
		end
	
	else
		ser = File.open(db_session_file) do |file|
			Marshal.load(file)
		end
	end
	session = DropboxSession.deserialize(ser)

	client = DropboxClient.new(session, :dropbox)
	uid = client.account_info()["uid"]
	file = open(file_path)
	filename = file_path.split('/')[-1]
	#warning - overwrite is enabled
	response = client.put_file("Public/"+filename,file)
	puts response

	filename = response["path"].split('/')[-1]
	escaped = URI.escape(filename)
	path = "http://dl.dropbox.com/u/#{uid}/"+escaped
	
	puts path
	return path
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
	opt.separator  "**COMMANDS**"
	opt.separator  "     ul:     Uploads a file to an S3 bucket. "
	opt.separator  "          	 USAGE: s3 ul -f FILE [-e EMAIL1,EMAIL2... ]"
	opt.separator  "     expire: Generate expiring link to a file with time in seconds. Time is optional, and will default to 3600 seconds."
	opt.separator  "          	 USAGE: s3 expire -f FILE [-t TIME] [-e EMAIL1,EMAIL2... ]"
	opt.separator  "     torrent: Generate a public torrent for a specified file."
	opt.separator  "          	 USAGE: s3 torrent -f FILE [-e EMAIL1,EMAIL2... ]"
	opt.separator  ""
	opt.separator  " As shown above, all of the commands can be optionally used with the email -e switch, followed by a comma-separated list of email addresses."
	opt.separator  ""
	opt.separator  ""
		
	opt.separator  "**OPTIONS**"

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

	opt.on("-d","--db","Upload to dropbox instead of s3") do
		options[:db] = true
	end

	opt.on("-h","--help","help") do
		puts s3rb
	end
end

s3rb.parse!

case ARGV[0]
when "ul"
	if !options[:file]
		puts "Usage: s3 ul -f FILE"
	elsif ((options[:imgur] and options[:db]) or (options[:imgur] and options[:cl]) or (options[:db] and options[:cl]))
		puts "ERROR! Use only one of --imgur, --cl or --db"
	else
		if options[:imgur]
			url = imgurupload(options[:file])
		elsif options[:cl]
			url = clupload(options[:file])
		elsif options[:db]
			url = db(options[:file])
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
		puts "Usage: s3 torrent -f FILE"
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