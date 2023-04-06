class Message < ApplicationRecord
  after_create_commit :notify_new_message

  private

  def notify_new_message
    broadcast_replace_to(
      'turbo_chat',
      target: 'message-count',
      html: "<span id='message-count'>#{self.class.count}</span>"
    )

    broadcast_prepend_to(
     'turbo_chat',
      partial: 'message',
      locals: { message: self },
      target: 'message-list'
    )
  end
end
