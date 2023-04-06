# frozen_string_literal: true

require 'action_cable/subscription_adapter/async'

module ActionCable
  module SubscriptionAdapter
    class Sqlite < Async
      def initialize(*)
        super
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
          with_broadcast_connection do |sqlite_conn|
            sqlite_conn.execute(
              'INSERT INTO messages VALUES (?, ?, ?)',
              nil,
              channel,
              JSON.dump(payload)
            )
          end
        end
      end

      def shutdown
        @listener.shutdown
      end

      def with_subscriptions_connection
        ar_conn = nil
        ActionCableRecord.connected_to(role: :reading) do
          ar_conn = ActionCableRecord.connection_pool.checkout.tap do |conn|
            # Action Cable is taking ownership over this database connection, and
            # will perform the necessary cleanup tasks
            ActionCableRecord.connection_pool.remove(conn)
          end
          sqlite_conn = ar_conn.raw_connection
          verify!(sqlite_conn)
          sqlite_conn.results_as_hash = true
          yield sqlite_conn
        end
      ensure
        ar_conn&.disconnect!
      end

      def with_broadcast_connection
        ActionCableRecord.connected_to(role: :writing) do
          ActionCableRecord.connection_pool.with_connection do |conn|
            sqlite_conn = conn.raw_connection
            verify!(sqlite_conn)
            yield sqlite_conn
          end
        end
      end

      private

      def listener
        @listener || @server.mutex.synchronize { @listener ||= Listener.new(self) }
      end

      def verify!(sqlite_conn)
        return if sqlite_conn.is_a?(SQLite3::Database)

        raise 'The Active Record database must be SQLite in order to use the SQLite Action Cable storage adapter'
      end

      class Listener
        def initialize(adapter)
          super()

          @adapter = adapter

          @poll_interval = 0.02
          @shutdown = false
          @latest_message_id = nil

          # https://guides.rubyonrails.org/threading_and_code_execution.html#wrapping-application-code
          @thread = Thread.new do
            Rails.application.executor.wrap do
              Thread.current.abort_on_exception = true
              listen
            end
          end
        end

        def listen
          @adapter.with_subscriptions_connection do |sqlite_conn|
            ActionCableRecord.migrate
            save_latest_message_id(sqlite_conn)

            loop do
              until @shutdown
                broadcast_new_messages(sqlite_conn)
                sleep @poll_interval
              end
            end
          end
        end

        def save_latest_message_id(sqlite_conn)
          # assuming no negative autoincrement ids, so we default ot -1 if there are no messages yet
          @latest_message_id = sqlite_conn.get_first_value(<<-STATEMENT.squish) || -1
            SELECT * FROM messages ORDER BY id desc LIMIT 1
          STATEMENT
        end

        def broadcast_new_messages(sqlite_conn)
          rows = sqlite_conn.execute(<<-STATEMENT.squish)
            SELECT * FROM messages WHERE id > #{@latest_message_id}
          STATEMENT
          rows.each do |row|
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

      class ActionCableRecord < ActiveRecord::Base
        self.abstract_class = true
        self.table_name = 'messages'

        connects_to database: { writing: :action_cable, reading: :action_cable }

        def self.migrate
          unless table_exists?
            connection.create_table table_name do |t|
              t.text :channel, null: false
              t.blob :message, null: false
            end
          end
        end
      end
    end
  end
end
