#!/usr/bin/env bash

# Install ruby, xclip and gems
sudo apt-get install xclip
sudo apt-get install ruby1.9.1
curl http://production.cf.rubygems.org/rubygems/rubygems-1.8.12.tgz --O rubygems-1.8.12.tgz
tar -xzvf rubygems-1.8.12.tgz
cd rubygems-1.8.12
sudo ruby setup.rb

# Update rubygems
update_rubygems

# Install needed gems
sudo gem install json
sudo gem install rest_client
sudo gem install cloudapp_api
sudo gem install highline
sudo gem install encrypted_strings
sudo gem install aws-s3
sudo gem install mail
sudo gem install ruby-gmail

# Download and install script
curl https://raw.github.com/hardikr/mishare/master/mishare.rb --O mishare
sudo cp mishare.rb /usr/bin/mishare
sudo chmod a+x /usr/bin/mishare

# Run
mishare