require 'elasticsearch/model'

class Team < ActiveRecord::Base
  # status
  STATUS_ACTIVE = 1
  STATUS_NOT_VERIFIED = 2
  STATUS_PENDING_CREATE = 3
  STATUS_DISABLED = 4
  STATUS_DELETED = 5
  STATUS_PENDING_DELETE = 6

  STATUS_NAMES = { STATUS_ACTIVE => "active", STATUS_NOT_VERIFIED => "not verified", STATUS_PENDING_CREATE => "pending create",
                   STATUS_DISABLED => "disabled", STATUS_DELETED => "deleted", STATUS_PENDING_DELETE => "pending delete"}

  # relations
  has_many :users
  has_many :clusters

  belongs_to :primary_admin, class_name: "User", foreign_key: "primary_admin_user_id"
  belongs_to :main_cluster, class_name: "Cluster", foreign_key: "main_cluster_id"

  has_many :invitations

  has_many :log_systems

  # validates
  VALID_TEAM_REGEX = /[a-z](-[a-z\d]|[a-z\d])+/i


  ### validations
  validates :name, presence: true, length: {minimum: 2, maximum: 20 }, format: { with: VALID_TEAM_REGEX }
  validates_uniqueness_of :name, conditions: -> { where.not(status: STATUS_DELETED) }
  validates :name, format: { without: /\s/ }


  # for avatar
  has_attached_file :avatar, {
      url: "/images/teams/:team_name/avatar.:style.:extension",
      #url: "/users/t/:attachment/:id_partition/:style/:hash.:extension",
      hash_secret: "GexImagesgYjAi06",
      :styles => {
          :thumb => ["100x100#",:png],
          :medium => ["200x200#",:jpg],
          :original => ["800x800", :jpg],
      },
      :convert_options => {:thumb => Proc.new{Gexcore::ImagesHelpers.convert_options}}
  }
  validates_attachment_content_type :avatar, content_type: /\Aimage\/.*\Z/

  # gravatar
  include Gravtastic
  gravtastic



  ### properties
  def to_s
    name
  end

  ### search
  paginates_per 10

  ### search
  searchable_by_simple_filter

  ### search elasticsearch
  include TeamElasticsearchSearchable

  # fields
  FIELDS_COMMON = ['name', 'about']
  FIELDS_COMMON_MAPPING = {'name'=>'Name', 'about'=>'About'}
  FIELDS_COMMON_MAPPING_RESPONSE = {'name'=>'Name', 'about'=>'About'}


  ### scopes
  scope :w_active, -> { where('status = ?', STATUS_ACTIVE) }

  scope :of_q, lambda {  |q| where_q(q) }

  def self.where_q(q)

    #w_active.where("name LIKE ?", "#{q}%")
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
        w_s << " name LIKE :#{p} "
        w_p[:"#{p}"] = "#{s}%"
        ind += 1
      end

      if w_s.count > 0
        w_active.where(w_s.join(" OR "), w_p)
      else
        w_active
      end
    end

  end



  ### callbacks
  before_create :_before_create

  def _before_create
    self.status ||= STATUS_ACTIVE
  end

  #
  def self.get_by_uid(uid)
    Team.where(uid: uid).first
  end

  def self.get_by_name(name)
    Team.where(name: name).first
  end

  ### info
  def to_hash
    {
        name: name,
        about: about.present? ? about.truncate(800) : '',
        createdAt: created_at
    }
  end

  def to_hash_with_images
    to_hash.merge(avatarUrl: ApplicationController.helpers.avatar_url_team(self, :medium))
  end

  ### status

  def active?
    return self.status == STATUS_ACTIVE
  end


  ### operations with status
  def activate!
    self.status = STATUS_ACTIVE
    save
  end

  def self.for_filter_statuses
    d = STATUS_NAMES.invert
    a = [["all", -1]]
    d.to_a.each do |t|
      a << t
    end
    a
  end

end
