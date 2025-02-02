class JobRecord < ApplicationRecord
  belongs_to :user

  validates :title, :company, :description, presence: true
end
