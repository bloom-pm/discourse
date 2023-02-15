#! /bin/sh
cd /var/www/discourse

if [ "$DEPLOYMENT_GROUP_NAME" == "communityBlueGreen" ]
then
    export SECRET_NAME=prod/discourse/app
fi

if [ "$DEPLOYMENT_GROUP_NAME" == "community-testing-blue-green" ]
then
    export SECRET_NAME=testing/discourse/app
fi

aws secretsmanager get-secret-value --secret-id $SECRET_NAME  --query SecretString --output text | jq -r "to_entries|map(\"\(.key)=\\\"\(.value|tostring)\\\"\")|.[]" > /var/www/discourse/.env

docker-compose build
