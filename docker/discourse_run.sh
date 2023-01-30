#!/bin/bash
set -x
set -e
env

OPTION=$1
bundle config set --local deployment 'true'

if [[ $OPTION == "compile" || -f discourse_first_run ]]; then
  rm -Rf discourse_first_run
  bundle exec rake plugin:pull_compatible_all RAILS_ENV=production
  find /var/www/discourse/vendor/bundle -name tmp -type d -exec rm -rf {} +
  mkdir /var/www/discourse/public/javascripts
  bundle exec rake db:prepare
  bundle exec rake assets:precompile
  bundle exec rake s3:upload_assets
  bundle exec rake s3:expire_missing_assets
fi

#PIDFILE=/var/www/discourse/pids/puma.pid bundle exec rails s

echo $RUBY_ALLOCATOR

rm -Rf /var/www/discourse/tmp/pids/unicorn.pid
touch /var/www/discourse/tmp/pids/unicorn.pid
chmod 0777 /var/www/discourse/tmp/pids/unicorn.pid
touch /var/www/discourse/log/unicorn.stderr.log
chmod 0777 /var/www/discourse/log/unicorn.stderr.log
rm -Rf /var/www/discourse/log/production.log
touch  /var/www/discourse/log/production.log
chmod 0664  /var/www/discourse/log/production.log
sudo chown -R discourse:discourse /var/www/discourse

runsvdir /etc/service &

LD_PRELOAD=$RUBY_ALLOCATOR HOME=/home/discourse USER=discourse UNICORN_BIND_ALL=1 UNICORN_PORT=3000 exec thpoff chpst -u discourse:www-data -U discourse:www-data bundle exec config/unicorn_launcher -E production -c config/unicorn.conf.rb
