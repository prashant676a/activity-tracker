class Company < ApplicationRecord
  # Associations
  has_many :users, dependent: :restrict_with_error
  has_many :activities, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true

  scope :with_tracking_enabled, -> { where(activity_tracking_enabled: true) }

  def tracking_enabled_for?(activity_type)
    return false unless activity_tracking_enabled

    config = activity_tracking_config.with_indifferent_access
    enabled_types = config[:enabled_activity_types] || Activity::ACTIVITY_TYPES

    enabled_types.include?(activity_type.to_s)
  end
end
