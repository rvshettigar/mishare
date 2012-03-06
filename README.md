#Mishare

Mishare (pronounced my-share) is a command line interface for Amazon S3, Dropbox, Cloudapp and Imgur using Ruby and the AWS SDK for Ruby.

You need xclip, ruby and gems instaled to use this. 

**Warning: Storing passwords uses symmetrical encryption, and this is certainly not the best way if you are on a shared computer!**

##Installation

The shell-file install shown below installs ruby1.9.1, rubygems(and a few gems: list is below) and xclip. I suggest you check out the script for yourself before running anything.

### Ubuntu only (one-line install):
    
    curl https://raw.github.com/hardikr/mishare/master/install.sh | sh

###Manual Install
If you want to manually install everything, or for other operating systems, check below:

####1) Installing Requirements (for Ubuntu)

    sudo apt-get install xclip
    sudo apt-get install ruby1.9.1
    curl http://production.cf.rubygems.org/rubygems/rubygems-1.8.12.tgz --O rubygems-1.8.12.tgz
    tar -xzvf rubygems-1.8.12.tgz
    cd rubygems-1.8.12
    sudo ruby setup.rb
    
    sudo gem install json
    sudo gem install rest_client
    sudo gem install cloudapp_api
    sudo gem install highline
    sudo gem install encrypted_strings
    sudo gem install aws-s3
    sudo gem install mail
    sudo gem install ruby-gmail
    
#### 2) Grab the script, copy to /usr/bin and make it executable.

    curl https://raw.github.com/hardikr/mishare/master/mishare.rb --O mishare
    sudo cp mishare.rb /usr/bin/mishare
    sudo chmod a+x /usr/bin/mishare

#### 3) Now run the script.
    
    mishare

It should prompt you for credentials as and when it requires them.

## Examples
PS : By default, if you don't provide any flags, the script assumes you mean upload to S3.
PS 2: The URL is copied to clipboard in all the below examples.

### Upload a file

    mishare ul -f file.txt
    
### Upload and email
Upload a file and email it to john@doe.com

    mishare ul -f file.txt -e john@doe.com

### Generate torrent
Generate public torrent URL for file.txt (S3 ONLY)

    mishare torrent -f file.txt

### Generate expiring link
Generate public authenticated URL that expires after 180 seconds and email it to john@doe.com (S3 ONLY)

    mishare expire -f file.txt -t 180 -e john@doe.com

### Upload to Dropbx
Upload file.txt to Dropbox and email it to john@doe.com and jane@doe.com

    mishare email -f file.txt -e john@doe.com jane@doe.com -d

### Upload to Cloudapp
Upload file.txt to Cloudapp and email it to john@doe.com and jane@doe.com

    mishare email -f file.txt -e john@doe.com jane@doe.com -c

### Upload to imgur.

    mishare ul -f file.jpg -i


## Credits

Huge thanks to:

[@dcparker](https://github.com/dcparker) for the [ruby-gmail gem](https://github.com/dcparker/ruby-gmail).

[@marcel](https://github.com/marcel) for the amazing [aws-s3 Ruby SDK](http://amazon.rubyforge.org/).

## LICENSE

    (The MIT License)
    
    Copyright (c) 2011 Hardik Ruparel, h@rdik.org
    
    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    'Software'), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:
    
    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
