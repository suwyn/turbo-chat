# Turbo Chat

Simple application to show off turbo streams

## Setup

Run the following from the command line:

```
git clone git@github.com:suwyn/turbo-chat.git \
  && cd turbo-chat \
  && docker-compose build
```

## Running

Run `docker-compose up` to start the web app accessible at `http://localhost:3000`.

Optionally, start the chatbot task by running `docker-compose run app rails chatbot:start`
