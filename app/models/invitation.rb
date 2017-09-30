class Invitation < ActiveRecord::Base

  # status
  STATUS_ACTIVATED = 1
  STATUS_NOT_ACTIVATED = 2
  STATUS_EXPIRED = 3
  STATUS_DELETED = 4

  STATUS_NAMES = { STATUS_ACTIVATED => "activated", STATUS_NOT_ACTIVATED => "not activated", STATUS_EXPIRED => "expired",
                   STATUS_DELETED => "deleted"}

  # invitation_type
  TYPE_MEMBER = 1
  TYPE_SHARE  = 2

  TYPE_NAMES = { TYPE_MEMBER => "invite", TYPE_SHARE => "share invite"}

  belongs_to :team
  belongs_to :cluster
  #belongs_to :user
  belongs_to :user, class_name: "User", foreign_key: 'from_user_id'

  ### properties
  def to_s
    name
  end

  # paging
  paginates_per 10

  ### search
  searchable_by_simple_filter

  ### scope
  scope :where_not_activated, -> { where(status: STATUS_NOT_ACTIVATED) }
  scope :for_cluster, -> (cluster_id) {where(:cluster_id => cluster_id)}

  ### properties

  def not_activated?
    status==Invitation::STATUS_NOT_ACTIVATED
  end

  def activated?
    status==Invitation::STATUS_ACTIVATED
  end



  def deleted?
    self.status==STATUS_DELETED
  end

  def expired?
    self.status==STATUS_EXPIRED || self.created_at<1.month.ago
  end

  def token
    uid
  end


  ### find
  def self.get_by_uid(uid)
    Invitation.where(uid: uid).first
  end

  ### search

  ### add
  def self.add_invite(email, master_user_id, team_id, status = STATUS_NOT_ACTIVATED)
    uid = Gexcore::TokenGenerator.generate_invitation_uid
    r = Invitation.new(uid: uid, from_user_id: master_user_id, team_id: team_id, to_email: email, status: status, invitation_type: TYPE_MEMBER)
    res = r.save

    r
  end

  def self.add_share(email, master_user_id, cluster_id, status = STATUS_NOT_ACTIVATED)
    uid = Gexcore::TokenGenerator.generate_share_uid
    cluster = Cluster.find(cluster_id)

    r = Invitation.new(uid: uid, from_user_id: master_user_id, team_id: cluster.team_id, cluster_id: cluster_id, to_email: email, status: status, invitation_type: TYPE_SHARE)
    res = r.save

    r
  end

  ### operations

  def make_accepted!
    self.activated_at = Time.now.utc
    self.status = STATUS_ACTIVATED

    save
  end

  def make_deleted!
    self.status = STATUS_DELETED
    save
  end

  # for invitations and share_invitations list
  def to_hash
    {:id => self.id, email: self.to_email, date: Gexcore::Common.date_format(self.created_at)}
  end

  def self.for_filter_statuses
    d = STATUS_NAMES.invert
    a = [["all statuses", -1]]
    d.to_a.each do |t|
      a << t
    end
    a
  end

  def self.for_filter_types
    d = TYPE_NAMES.invert
    a = [["all types", -1]]
    d.to_a.each do |t|
      a << t
    end
    a
  end

end
