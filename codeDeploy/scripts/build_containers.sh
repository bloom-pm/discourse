#! /bin/sh
cd /var/www/discourse

aws secretsmanager get-secret-value --secret-id prod/discourse/app  --query SecretString --output text | jq -r "to_entries|map(\"\(.key)=\\\"\(.value|tostring)\\\"\")|.[]" > /var/www/discourse/.env
docker-compose build
