ActiveSupport.on_load :action_cable do
  def self.pubsub_adapter
    SqliteSubscriptionAdapter
  end
end
