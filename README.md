#Mishare

Mishare (pronounced my-share) is a command line interface for Amazon S3, Dropbox, Cloudapp and Imgur using Ruby and the AWS SDK for Ruby.

You need xclip, ruby and gems instaled to use this. 

**Warning: This project is pre-alpha and while you can use it, I would advise caution since there may be kinks. One probable issue you may have is : GMail and Cloudapp passwords are stored in files using symmetrical encryption, and this is certainly not ideal! You should change the SECRET_KEY constant to your choice of secret key used for the encryption. I haven't found time to implement GMail OAuth yet, so you're welcome to fork and send in a pull-request.**

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
    sudo gem install dropbox-sdk
    sudo gem install gpgr
    
#### 2) Grab the script, copy to /usr/bin and make it executable.

    curl https://raw.github.com/hardikr/mishare/master/mishare.rb --O mishare
    sudo cp mishare.rb /usr/bin/mishare
    sudo chmod a+x /usr/bin/mishare

#### 3) Now run the script.
    
    mishare

It should prompt you for credentials as and when it requires them.

## Note:

*   The script defaults to S3, so there is no flag/switch for it.
*   The URL is copied to clipboard by default.
*   Use -g for PGP encryption. When using the -e flag for email, the script assumes you're using the public key of the same email address you've provided with -e flag, so you can use the -g option as a switch. If you provide a value to the -g flag, it will be ignored. For Example, in the below command, the file is encrypted and sent using `john@doe.com`'s public key, and `jane@doe.com` is ignored:

        mishare ul -f file.txt -e john@doe.com -g jane@doe.com
    
*   When not emailing the file, you need to provide at least one email address after -g flag (else script will return an error):

        mishare ul -f file.txt -g john@doe.com  # works
        mishare ul -f file.txt -g               # error

## Examples

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

### Upload to Dropbox
Upload file.txt to Dropbox and email it to john@doe.com and jane@doe.com

    mishare ul -f file.txt -e john@doe.com jane@doe.com -d

### Upload to Cloudapp
Upload file.txt to Cloudapp and email it to john@doe.com and jane@doe.com

    mishare ul -f file.txt -e john@doe.com jane@doe.com -c

### Upload to imgur.

    mishare ul -f file.jpg -i

### Encrypt file 
Encrypt using public keys of john@doe.com and jane@doe.com
    mishare ul -f file.txt -g john@doe.com jane@doe.com
    
### Encrypt and email 
Encrypt and email file to john@doe.com (will use public key of john@doe.com)
    mishare ul -f file.txt -e john@doe.com -g
    
## Command and Flag Help
    **COMMANDS**
     ul:     Uploads a file to an S3 bucket. 
               USAGE: mishare ul -f FILE [-e EMAIL1,EMAIL2... ]
     expire: Generate expiring link to a file with time in seconds. Time is optional, and will default to 3600 seconds. S3 ONLY
          	 USAGE: mishare expire -f FILE [-t TIME] [-e EMAIL1,EMAIL2... ]
     torrent: Generate a public torrent for a specified file. S3 ONLY
          	 USAGE: mishare torrent -f FILE [-e EMAIL1,EMAIL2... ]

     As shown above, all of the commands can be optionally used with the email -e switch, followed by a space-separated list of email addresses.


    **OPTIONS**
        -f, --file FILE                  which file you want to upload
        -e, --email EMAIL1,EMAIL2        which e-mail address you want to send the link of the uploaded file to
        -t, --time TIME                  Time(in secons) in which file expires. Defaults to 60 minutes
        -s, --ssl                        Use SSL (returns https URL)
        -i, --imgur                      Uploads image to imgur instead of s3
        -c, --cl                         Upload to cloudapp instead of s3
        -d, --db                         Upload to dropbox instead of s3
        -g EMAIL1,EMAIL2                 Encrypt file using public key(s) of email address(es)
        -h, --help                       help


## Stuff you should know
*   Amazon S3 assumes overwrite to true, by default.
*   Dropbox assumes overwrite to false, by default.

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
