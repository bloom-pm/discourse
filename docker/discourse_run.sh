#!/bin/bash
set -x 
set -e
env

OPTION=$1
bundle config set --local deployment 'true'
bundle config mirror.https://rubygems.org http://localhost:9292
bundle config mirror.https://github.com http://localhost:9292

if [[ $OPTION == "compile" ]]; then
  bundle exec rake plugin:pull_compatible_all RAILS_ENV=production
  find /var/www/discourse/vendor/bundle -name tmp -type d -exec rm -rf {} +
  bundle exec rake db:prepare
  bundle exec rake assets:precompile 
fi

#PIDFILE=/var/www/discourse/pids/puma.pid bundle exec rails s

echo $RUBY_ALLOCATOR

rm -Rf /var/www/discourse/tmp/pids/unicorn.pid
touch /var/www/discourse/tmp/pids/unicorn.pid
chmod 0777 /var/www/discourse/tmp/pids/unicorn.pid
touch /var/www/discourse/log/unicorn.stderr.log
chmod 0777 /var/www/discourse/log/unicorn.stderr.log
LD_PRELOAD=$RUBY_ALLOCATOR HOME=/home/discourse USER=discourse UNICORN_BIND_ALL=1 UNICORN_PORT=3000 exec thpoff chpst -u discourse:www-data -U discourse:www-data bundle exec config/unicorn_launcher -E production -c config/unicorn.conf.rb