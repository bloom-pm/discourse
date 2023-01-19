This is a fork of the discourse repo based out of the last stable version (3.0.0) with Docker configuration 

The docker folder was added, plus the following files were added: .env.example .env.example.dev docker-compose.yml docker-compose.dev.yml

Run development mode 

docker-compose  --env-file .env.example.dev -f docker-compose.yml -f docker-compose.dev.yml up --build

Run on server 

Create .env file, point to live postgres 

docker-compose up -d 
