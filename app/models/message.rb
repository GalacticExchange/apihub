class Message < ActiveRecord::Base
  STATUS_ACTIVE = 1
  STATUS_DELETED = 2

    #
  belongs_to :message_dialog, foreign_key: 'dialog_id'
  belongs_to :from_user, class_name: 'User', foreign_key: 'from_user_id'
  belongs_to :to_user, class_name: 'User', foreign_key: 'to_user_id'

  #
  #paginates_per 50
  #self.per_page = 50

  # validations
  validates :message, :presence => true
  # callbacks
  before_create :_before_create

    # paging
  paginates_per 10

    ### search
  searchable_by_simple_filter

  ### callbacks

  def _before_create
    self.status ||= STATUS_ACTIVE
  end


  ### data

  def to_hash
    {
        id: id,
        message: message,
        from: from_user.username,
        to: to_user.username,
        date: Gexcore::Common.date_format(self.created_at),
        isRead: true
    }
  end



  ### list

  def self.get_list(filter_params)
    q = Message.includes(:to_user, :from_user).where('1=1')

    # where

    # dialog
    dialog_id = filter_params.fetch(:dialog_id, nil)
    unless dialog_id.nil?
      q = q.where("dialog_id = ?", dialog_id)
    end

    user_id = filter_params.fetch(:user_id, nil)
    unless user_id.nil?
      q = q.where("to_user_id = ? or from_user_id = ?", user_id, user_id)
    end


    # paging
    q = q.order('id desc').limit(100)

    q
  end



end
