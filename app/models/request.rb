# frozen_string_literal: true

class Request < ApplicationRecord
  include Hashid::Rails
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  before_save { self.requester_mail = requester_mail.downcase }
  validates :requester_name, presence: true
  validates :requester_extension, presence: true
  validates :requester_phone, presence: true
  validates :requester_id, presence: true
  validates :requester_mail, presence: true,
            format: { with: VALID_EMAIL_REGEX }
  validates :requester_type, presence: true
  validates :work_type, presence: true
  validates :work_description, presence: true

  has_many :tasks
  has_many :employees, through: :tasks
  has_many :task_observations, -> { order(created_at: :asc) }, through: :tasks
  belongs_to :campus

  has_many :request_deny_reasons
  accepts_nested_attributes_for :request_deny_reasons, allow_destroy: true, reject_if: proc { |attr|
    attr['reason'].blank?
  }

  has_many :reopen_reasons
  accepts_nested_attributes_for :reopen_reasons, allow_destroy: true, reject_if: proc { |attr|
    attr['reason'].blank?
  }

  has_one :request_location
  attribute :work_location, :integer
  attribute :work_building, :integer
  has_one :feedback, dependent: :destroy

  has_many :log_entries, -> { order(created_at: :asc) }, dependent: :destroy

  def employees_currently_working
    UserAccount.where(id: tasks.where(active: true, request_id: self.id).pluck(:user_account_id),
                      role: 'worker', status: 'Activo')
  end

  def employees_not_working
    UserAccount.where.missing(:tasks).and(
      UserAccount.where(role: 'worker', status: 'Activo')
    ).or(
      UserAccount.where(id: tasks.where(active: false, request_id: self.id).pluck(:user_account_id),
                        role: 'worker', status: 'Activo')
    ).or(
      UserAccount.where.not(id: tasks.where(request_id: self.id).pluck(:user_account_id)).and(
        UserAccount.where(role: 'worker', status: 'Activo')
      )
    ).distinct
  end

  def average_worked
    max = 0
    if tasks.where.not(finished_at: nil).pluck(:finished_at).max
      max = tasks.where.not(finished_at: nil).pluck(:finished_at).max
    end
    min = 0
    if tasks.where.not(started_at: nil).pluck(:started_at).min
      min = tasks.where.not(started_at: nil).pluck(:started_at).min
    end
    ((max - min) / 1.day).round(2)
  end
end
