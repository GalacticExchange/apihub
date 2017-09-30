class User < ActiveRecord::Base

  #dragonfly_accessor :photo
  # status
  STATUS_ACTIVE = 1
  STATUS_NOT_VERIFIED = 2
  STATUS_PENDING_CREATE = 3
  STATUS_DISABLED = 4
  STATUS_DELETED = 5
  STATUS_PENDING_DELETE = 6

  STATUS_NAMES = { STATUS_ACTIVE => "active", STATUS_NOT_VERIFIED => "not verified", STATUS_PENDING_CREATE => "pending create",
                   STATUS_DISABLED => "disabled", STATUS_DELETED => "deleted", STATUS_PENDING_DELETE => "pending delete"}

  ADMIN_STATUS_NAMES_FOR_USER = { STATUS_ACTIVE => "active", STATUS_DISABLED => "disabled", STATUS_DELETED => "deleted" }


  # validations
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\Z/i
  VALID_USERNAME_REGEX = /\A[a-z](-[a-z\d]|[a-z\d])+\Z/i

#=begin
  #
  validates_presence_of     :password, :if => :password_required?
  validates_confirmation_of :password, :if => :password_required?
  validates_length_of       :password, :within => 8..64, :allow_blank => true


  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end
#=end
  #validates :password, presence: true, length: { minimum: 8, maximum: 50 }
  #validates :password, confirmation: true
  #validates :password_confirmation, presence: true


  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }
  validates_uniqueness_of :email, :case_sensitive => false, conditions: -> { where.not(status: STATUS_DELETED) }

  validates :username, presence: true, length: {minimum: 2, maximum: 20 }, format: { with: VALID_USERNAME_REGEX }
  validates_uniqueness_of :username, :case_sensitive => false, conditions: -> { where.not(status: STATUS_DELETED) }

  validates :firstname, presence: true, length: {minimum: 2, maximum: 32 }
  validates :lastname, presence: true, length: {minimum: 2, maximum: 32 }

  validates_associated :team

  #validates :phone_number, phone: true
  validates_uniqueness_of :phone_number, conditions: -> { where.not(phone_number: Gexcore::Settings.TEST_PHONE_NUMBER) }


  # fields
  FIELDS_COMMON = ['firstname', 'lastname', 'about']
  FIELDS_COMMON_MAPPING = {'firstname'=>'firstName', 'lastname'=>'lastName', 'about'=>'about'}
  FIELDS_COMMON_MAPPING_RESPONSE = {'firstname'=>'firstName', 'lastname'=>'lastName', 'about'=>'about'}


  # devise
  devise  :database_authenticatable,
          #:registerable,
          :confirmable,
          :recoverable,
          :rememberable,
          :trackable,
          # :lockable,
          #:validatable

          :authentication_keys => [:login]

  #
  belongs_to :team
  accepts_nested_attributes_for :team

  belongs_to :group

  #has_one :own_cluster, class_name: "Cluster", foreign_key: "primary_admin_user_id"

  has_many :invitations
  has_many :log_user_actions

  has_many :keys

  #
  scope :w_not_deleted, -> { where('status != ?', STATUS_DELETED) }
  scope :w_active, -> { where('status = ?', STATUS_ACTIVE) }

  ### callbacks
  before_create :_before_create
  after_create :_after_create
  #after_save :add_to_elastic

  ###

  # for avatar
  has_attached_file :avatar, {
      url: "/images/users/:user_username/avatar.:style.:extension",
      #url: "/users/u/:attachment/:id_partition/:style/:hash.:extension",
      hash_secret: "GexImagesgYjAi06",
      :styles => {
          :thumb => ["100x100#",:png],
          :medium => ["200x200#",:png],
          :original => ["800x800", :png],
      },
      :convert_options => {:thumb => Proc.new{Gexcore::ImagesHelpers.convert_options}}
  }

  validates_attachment_content_type :avatar, content_type: /\Aimage\/.*\Z/

  # gravatar
  include Gravtastic
  gravtastic


  ### search
  paginates_per 10

  ### search
  searchable_by_simple_filter



  ### devise - rememberable
  attr_accessor :signed_in_via_remember
  def after_remembered
    update_attribute(:signed_in_via_remember, true)
  end

  def signed_in_via_remember?
    return false if signed_in_via_remember.nil?

    signed_in_via_remember
  end


  ### properties
  def login=(login)
    @login = login
  end

  def login
    @login || self.username || self.email
  end


  def yt_info
    JSON.parse(self.customer_info) if self.customer_info

  end

  def registration_options_hash
    return @registration_options_hash unless @registration_options_hash.nil?

    return nil if self.registration_options.nil?

    @registration_options_hash = JSON.parse(self.registration_options) rescue {}

    @registration_options_hash
  end

  ### devise
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_hash).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      conditions[:email].downcase! if conditions[:email]
      where(conditions.to_hash).first
    end
  end

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      if conditions[:username].nil?
        where(conditions).first
      else
        where(username: conditions[:username]).first
      end
    end
  end


  ### find
  def self.get_by_id(id)
    User.w_not_deleted.where(id: id).first
  end
  def self.get_by_email(email)
    User.w_not_deleted.where(email: email).first
  end
  def self.get_by_username(username)
    User.w_not_deleted.where(username: username).first
  end
  def self.get_by_username_or_email(username)
    User.w_not_deleted.where(["username = ? OR email = ?", username, username]).first
  end

  ### search elasticsearch
  include UserElasticsearchSearchable


  ### search
  paginates_per 10

  searchable_by_simple_filter

  scope :of_q, lambda {  |q| where_q(q) }

  def self.where_q(q)

    if q.nil? || q.blank?
      w_active
    else
      # split by words
      words = Gexcore::SearchServiceBase.split_string_by_words(q)

      w_s = []
      w_p = {}
      ind = 1
      words.each do |s|
        p = "q#{ind}"
        w_s << " firstname LIKE :#{p} OR lastname LIKE :#{p} OR username LIKE :#{p} "
        w_p[:"#{p}"] = "#{s}%"
        ind += 1
      end

      if w_s.count > 0
        w_active.where(w_s.join(" OR "), w_p)
      else
        w_active
      end

      #w_active.where("firstname LIKE :q OR lastname LIKE :q OR username LIKE :q", {:q => "#{q}%"})

    end
  end



  ### callbacks

  def _before_create
    self.email = email.downcase


  end

  def _after_create

  end


  ### permissions
  delegate :can?, :cannot?, :to => :ability

  def ability
    #require 'ability'

    @ability ||= Gexcore::Myability.new(self)
  end

  ###

  # group of the user in the cluster == group of user in team
  def group_id_in_cluster(cluster_id=nil)
    #cluster_id ||= self.main_cluster_id
    return nil if cluster_id.nil?

    # if not our cluster
    #return nil if self.main_cluster_id!=cluster_id

    #
    self.group_id
  end

=begin
  # before 2015-oct
  def group_id_in_cluster(cluster_id=nil)
    cluster_id ||= self.main_cluster_id

    return nil if cluster_id.nil?

    #
    ug = self.user_groups.where(cluster_id: cluster_id).first
    return nil if ug.nil?

    ug.group_id
  end
=end



  ### group
  def is_superadmin?
    return self.group_id == Group.group_superadmin.id
  end

  ### deleted
  def deleted?
    self.status==STATUS_DELETED
  end

  def verified?
    #self.verified_at.present? && self.status!=STATUS_NOT_VERIFIED
    self.status!=STATUS_NOT_VERIFIED
  end

  def active?
    self.status==STATUS_ACTIVE
  end


  ### verify

  def verify!
    self.confirmed_at = Time.now.utc
    self.status = STATUS_ACTIVE

    save
  end


  ### properties
  def group_name
    return nil if group_id.nil?

    name = Group.find(group_id).name
    return name
  end

  def to_hash
    #
    data = {username: username, role: self.group_name}

    # add common fields
    User::FIELDS_COMMON_MAPPING.each do |f, f_new|
      data[f_new.to_sym] = self[f.to_sym] || ''
    end

    data
  end

  def to_hash_public
    #
    data = {username: username}

    # add common fields
    User::FIELDS_COMMON_MAPPING.each do |f, f_new|
      data[f_new.to_sym] = self[f.to_sym] || ''
    end

    #user avatar & team
    data[:avatar_url] = ApplicationController.helpers.avatar_url(self, :medium)
    data[:team_name] = self.team.name

    data
  end

  def to_hash_admin
    #
    data = {username: username, role: self.group_name, email: email}

    # add common fields
    User::FIELDS_COMMON.each do |f|
      data[f] = self[f] || ''
    end

    data[:team_name] = self.team.name

    data[:country] = self.country
    data[:phone_number] = self.phone_number

    data[:password] = self.password

    data
  end


  def to_hash_share_user
    #
    data = {username: username}

    # add common fields
    User::FIELDS_COMMON_MAPPING.each do |f, f_new|
      data[f_new.to_sym] = self[f.to_sym] || ''
    end

    #user avatar & team
    tmp_user = User.get_by_username(username)
    data[:avatar_url] = ApplicationController.helpers.avatar_url(tmp_user, :thumb)
    data[:team_name] = tmp_user.team.name


    data
  end

  def self.for_filter_statuses
    d = STATUS_NAMES.invert
    a = [["all", -1]]
    d.to_a.each do |t|
      a << t
    end
    a
  end


  ### validation
  validate :forced_to_be_invalid

  def make_not_valid!
    @not_valid = true
  end

  def forced_to_be_invalid
    errors.add(:base, ' user invalid') if @not_valid
  end



  ### phone
  def validate_phone
    if !Phoner::Phone.valid?(self.phone_number)
      errors.add(:phone_number, "invalid")

      make_not_valid!
    end
  end

  # for elasticsearch cluster index
  def add_to_elastic
    row_hash = self.build_model_hash
    #Gexcore::LogModelToElasticsearch.model_to_elasticsearch(row_hash)
    ModelWorker.perform_async(row_hash) if row_hash
  end

  def build_model_hash
    array_of_change_fields = self.changed
    change_fields = ['username', 'email']
    if !(array_of_change_fields & change_fields).empty?
      row_hash = {}
      row_hash[:username] = self.username
      row_hash[:id] = self.id
      row_hash[:type_name] = self.class.name.downcase.pluralize

      return row_hash
    end

    nil
  end

end
