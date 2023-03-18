namespace :chatbot do
  desc "Start the chatbot"
  task start: :environment do
    begin
      Message.create!(text: 'Chatbot has entered the room :)')

      EM.run do
        message_number = 0

        EM.add_periodic_timer(15.seconds) do
          message_number += 1
          puts "Chat bot posting message #{message_number}"
          Message.create!(text: "Message #{message_number} from the Chatbot!")
        end
      end
    ensure
      Message.create!(text: 'Chatbot has left the room :(')
    end
  end
end
