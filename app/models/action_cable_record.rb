class ActionCableRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :action_cable, reading: :action_cable }
end
