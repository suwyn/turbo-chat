class MessagesController < ActionController::Base
  layout 'application'

  def index

  end

  def create
    Message.create!(create_params)

    redirect_back fallback_location: root_path
  end

  private

  def create_params
    params.require(:message).permit(:text)
  end
end
