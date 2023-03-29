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

## SQLite Action Cable Subscription Adapater Solution

- Inherit from async adapter
- Setup sqlite database to store broadcast messages+channels
- Broadcasts are written to a table
- A listener (1 per adapter, which is 1 per action cable server) polls the database for new messages
  - Inefficient, but not terribly costly since it's a single connection.
  - Not sure how well it scales
- When listener finds new broadcasts, it passes them off to the async adapter implementation
- Probably needs WAL enabled to be responsive enough, since writes don't block reads, which allows the listener loop to keep getting new messages quickly.

## Potential Gotchas

> All processes using a database must be on the same host computer; WAL does not work over a network filesystem.

https://www.sqlite.org/wal.html
