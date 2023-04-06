class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # comment this out when using single database configuration
  connects_to database: {
    writing: :primary,
    reading: :primary_reader
  }
end
