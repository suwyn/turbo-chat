# frozen_string_literal: true

require 'action_cable/subscription_adapter/async'

module ActionCable
  module SubscriptionAdapter
    class Sqlite < Async
      def initialize(*)
        super

        @sqlite_connection = nil
        @sync = Mutex.new
        @listener = Listener.new(self)
      end

      # alias the existing broadcast method from Async adapter
      # so that we can call it from the listener
      alias broadcast_to_clients broadcast

      # overwrite the broadcast so that messages are stored
      # in sqlite, and let the listener pick them up and actually
      # broadcast them
      def broadcast(channel, payload)
        # must synchronize writes to sqlite because it does not
        # support concurrent writes to the same table
        @sync.synchronize do
          sqlite_connection.execute(
            'INSERT INTO action_cable_messages VALUES (?, ?, ?)',
            nil,
            channel,
            JSON.dump(payload)
          )
        end
      end

      def shutdown
        @listener.shutdown
      end

      def sqlite_connection
        @sqlite_connection ||= begin
          SQLite3::Database.new(sqlite_config['database']).tap do |db|
            db.results_as_hash = true
            # set busy handler?
            db.execute <<-SQL.squish
              CREATE TABLE IF NOT EXISTS action_cable_messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                channel TEXT NOT NULL,
                message BLOB NOT NULL
              )
            SQL
          end
        end
      end

      private

      def sqlite_config
        @server.config.cable.except(:channel_prefix)
      end

      class Listener
        def initialize(adapter)
          super()

          @adapter = adapter

          @poll_interval = 0.02
          @shutdown = false
          @latest_message_id = nil

          @thread = Thread.new do
            Thread.current.abort_on_exception = true
            listen
          end
        end

        def listen
          save_latest_message_id(@adapter.sqlite_connection)

          until @shutdown
            broadcast_new_messages(@adapter.sqlite_connection)
            sleep @poll_interval
          end
        end

        def save_latest_message_id(sqlite_conn)
          # assuming no negative autoincrement ids, so we default ot -1 if there are no messages yet
          @latest_message_id = sqlite_conn.get_first_value(<<-STATEMENT.squish) || -1
            SELECT * FROM action_cable_messages ORDER BY id desc LIMIT 1
          STATEMENT
        end

        def broadcast_new_messages(sqlite_conn)
          rows = sqlite_conn.execute(<<-STATEMENT.squish)
            SELECT * FROM action_cable_messages WHERE id > #{@latest_message_id}
          STATEMENT
          rows&.each do |row|
            begin
              message = JSON.parse(row['message'])
            rescue
              pp 'Bad message'
              next
            end
            @adapter.broadcast_to_clients(row['channel'], message)
            @latest_message_id = row['id']
          end
        end

        def shutdown
          @shutdown = true
          Thread.pass while @thread.alive?
        end
      end
    end
  end
end
