class Activity < ApplicationRecord
  # Constants
  ACTIVITY_TYPES = %w[
    login
    logout
    give_recognition
    receive_recognition
    profile_update
    admin_action
  ].freeze

  # Override user association to include discarded users
  # This ensures activities remain intact even if user is soft-deleted
  belongs_to :user, -> { with_discarded }
  belongs_to :company

  validates :activity_type, presence: true, inclusion: { in: ACTIVITY_TYPES }
  validates :occurred_at, presence: true
  validate :user_belongs_to_company

  before_validation :set_occurred_at
  before_validation :sanitize_metadata

  scope :recent, -> { order(occurred_at: :desc) }
  scope :for_company, ->(company_id) { where(company_id: company_id) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :by_type, ->(type) { where(activity_type: type) if type.present? }
  scope :between, ->(start_date, end_date) {
    where(occurred_at: date_range(start_date, end_date))
  }

  def self.filter_by_params(params)
    scope = all
    scope = scope.for_user(params[:user_id]) if params[:user_id]
    scope = scope.by_type(params[:activity_type]) if params[:activity_type]
    scope = scope.between(params[:start_date], params[:end_date])
    scope.recent
  end

  private

  def set_occurred_at
    self.occurred_at ||= Time.current
  end

  def sanitize_metadata
    return if metadata.blank?

    # Remove sensitive keys
    sensitive_keys = %w[password token secret api_key credit_card ssn]
    self.metadata = metadata.deep_stringify_keys.except(*sensitive_keys)
  end

  def user_belongs_to_company
    if user && user.company_id != company_id
      errors.add(:user, "must belong to the same company")
    end
  end

  def self.date_range(start_date, end_date)
    start_date = start_date.present? ? Date.parse(start_date.to_s).beginning_of_day : 100.years.ago
    end_date = end_date.present? ? Date.parse(end_date.to_s).end_of_day : 100.years.from_now
    start_date..end_date
  end
end
