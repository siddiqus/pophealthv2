class Practice
  include Mongoid::Document
  field :name, type: String

	validate :name, :uniqueness => true
    
end
