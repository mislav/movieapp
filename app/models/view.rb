class View
  include MongoMapper::EmbeddedDocument
  
  belongs_to :movie
  
  key :created_at, DateTime
  key :liked, Boolean
end
