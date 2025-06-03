# app/models/user.rb
class User < ApplicationRecord
  include Discard::Model
  default_scope -> { kept }

  belongs_to :company
  has_many :activities, dependent: :restrict_with_error

  validates :email, presence: true,
                    uniqueness: { scope: :company_id },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :role, inclusion: { in: %w[user company_admin admin] }

  scope :admins, -> { where(role: %w[admin company_admin]) }
  scope :active, -> { kept }  # Alias for clarity

  def admin?
    role == "admin"
  end

  def company_admin?
    role == "company_admin"
  end

  def can_view_activities?
    admin? || company_admin?
  end
end
