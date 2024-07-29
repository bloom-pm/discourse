#!/bin/bash

set -x
set -e
bundle config set --local deployment 'true'
bundle config set force_ruby_platform true
chown -R discourse:discourse /var/www/discourse
cd /var/www/discourse
sudo -u discourse bundle install --deployment --jobs 4 --without test
sudo -u discourse yarn install --production
sudo -u discourse yarn cache clean
bundle exec rake maxminddb:get
