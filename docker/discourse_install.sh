#!/bin/bash

set -x
set -e
bundle config set --local deployment 'true'
bundle config set --local --without test
bundle config mirror.https://rubygems.org http://localhost:9292
bundle config mirror.https://github.com http://localhost:9292
chown -R discourse:discourse /var/www/discourse
cd /var/www/discourse
sudo -u discourse bundle install --jobs 4
sudo -u discourse yarn install --production
sudo -u discourse yarn cache clean
bundle exec rake maxminddb:get
