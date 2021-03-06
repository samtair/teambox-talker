class Registration < ActiveRecord::Base

  belongs_to :user
  belongs_to :account

  validates_uniqueness_of :user_id, :scope => [:account_id]

  # named_scope :registered, :conditions => { :guest => false }
  # named_scope :guests, :conditions => { :guest => true }

end
