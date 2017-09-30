class MessageDialog < ActiveRecord::Base
  has_many :messages
  belongs_to  :last_message, class_name: 'Message', foreign_key: 'last_message_id'

  belongs_to :from_user, class_name: 'User'
  belongs_to :to_user, class_name: 'User'

  # scopes
  scope :w_for_user, lambda { |user_id| where_for_user(user_id) }

  ### create
  def self.get_by_users(from_user_id, to_user_id)
    MessageDialog.where(
        "(from_user_id = :from_user_id AND to_user_id = :to_user_id) OR (from_user_id = :to_user_id AND to_user_id = :from_user_id)",
        {from_user_id: from_user_id, to_user_id: to_user_id}
    ).first

  end

  ###
  def self.where_for_user(user_id)
    where(
        "(from_user_id = :user_id OR to_user_id = :user_id)",
        {user_id: user_id}
    )

  end

  def self.find_or_create_by_users(from_user_id, to_user_id)
    row = get_by_users(from_user_id, to_user_id)

    if !row
      row = MessageDialog.new(from_user_id: from_user_id, to_user_id: to_user_id)
      row.save
    end

    row
  end


  ###
  def to_hash(this_user_id)
    u = (this_user_id==from_user_id ? self.to_user : self.from_user)

    {
        user: u.to_hash,
        #username: (this_user_id==from_user_id ? self.to_user.username : self.from_user.username),
        lastMessageDate: Gexcore::Common.date_format(self.updated_at)
    }

  end

  def self.to_hash_no_dialog(this_user_id, to_user)
    {
        user: to_user.to_hash,
        lastMessageDate: nil
    }
  end

end
