# frozen_string_literal: true

# Enables additional Sqlite database configuration
# Place file in config/initializers

module AdditonalSqliteConfiguration
  # NOTE: Some of these are set once
  # and then retained across connections
  # some need to be set for every connection (busy_timeout, synchronous)
  PRAGMA_CONFIG = %i[
    journal_mode
    locking_mode
    page_size
    cache_size
    temp_store
    synchronous
    busy_timeout
    mmap_size
  ].freeze

  private

  def configure_connection
    configure_pragma
    attach_databases if @config.fetch(:attach, []).present?

    super
  end

  def configure_pragma(connection = @connection)
    # NOTE: the SQLite adapter handles validation
    (@config.keys & PRAGMA_CONFIG).each do |key|
      connection.send "#{key}=", @config[key]
    end
  end

  def attach_databases
    @config[:attach].each do |config_name|
      attach_config = Rails.configuration.database_configuration[Rails.env][config_name]

      @connection.execute("ATTACH DATABASE '#{attach_config['database']}' as #{config_name}")

      (attach_config.keys & PRAGMA_CONFIG.map(&:to_s)).each do |key|
        # NOTE: the sqlite adapter doesn't support databases in their PRAGMA functions
        # as the pragma name is hard coded so we have to execute ourselves.
        # https://github.com/sparklemotion/sqlite3-ruby/blob/master/lib/sqlite3/pragmas.rb#L117
        @connection.execute("PRAGMA #{config_name}.#{key}=#{attach_config[key]}")
      end
    end
  end
end

ActiveSupport.on_load :active_record_sqlite3adapter do
  prepend AdditonalSqliteConfiguration
end
