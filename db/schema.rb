# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170707094858) do

  create_table "application_images", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer  "library_application_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
  end

  create_table "aws_instance_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "name"
    t.boolean  "deprecated"
    t.boolean  "hadoop_compatible"
  end

  create_table "aws_region_instance_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer  "aws_region_id"
    t.integer  "aws_instance_type_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.index ["aws_instance_type_id"], name: "index_aws_region_instance_types_on_aws_instance_type_id", using: :btree
    t.index ["aws_region_id"], name: "index_aws_region_instance_types_on_aws_region_id", using: :btree
  end

  create_table "aws_regions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "name"
    t.string   "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cluster_access", id: :bigint, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer  "cluster_id", null: false
    t.integer  "user_id",    null: false
    t.datetime "created_at", null: false
    t.index ["cluster_id"], name: "cluster_id", using: :btree
    t.index ["created_at"], name: "created_at", using: :btree
    t.index ["user_id"], name: "user_id", using: :btree
  end

  create_table "cluster_applications", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string  "uid",                                                 null: false
    t.string  "name",                                                null: false
    t.integer "cluster_id",                                          null: false
    t.integer "library_application_id",                              null: false
    t.string  "title"
    t.integer "status",                 limit: 1,     default: 0,    null: false
    t.string  "admin_notes"
    t.text    "settings",               limit: 65535
    t.string  "notes"
    t.boolean "external",                             default: true
    t.index ["cluster_id"], name: "cluster_id", using: :btree
    t.index ["library_application_id"], name: "library_application_id", using: :btree
    t.index ["uid"], name: "uid", unique: true, using: :btree
  end

  create_table "cluster_containers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string  "uid",                                      null: false
    t.string  "basename",                                 null: false
    t.string  "name",                                     null: false
    t.integer "application_id",                           null: false
    t.integer "cluster_id",                               null: false
    t.integer "node_id"
    t.integer "status",         limit: 1,                 null: false
    t.boolean "is_master",                default: false, null: false
    t.string  "hostname"
    t.string  "public_ip"
    t.string  "private_ip"
    t.string  "ssh_port"
    t.string  "settings"
    t.index ["application_id"], name: "application_id", using: :btree
    t.index ["application_id"], name: "container_id", using: :btree
    t.index ["cluster_id"], name: "cluster_id", using: :btree
    t.index ["node_id"], name: "node_id", using: :btree
    t.index ["public_ip"], name: "host", using: :btree
    t.index ["status"], name: "ip", using: :btree
  end

  create_table "cluster_hadoop_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string  "name",                   null: false
    t.string  "title",                  null: false
    t.boolean "enabled", default: true, null: false
    t.integer "pos",     default: 0,    null: false
    t.index ["id"], name: "id", unique: true, using: :btree
    t.index ["name"], name: "name", unique: true, using: :btree
  end

  create_table "cluster_service_endpoints", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "cluster_id",   null: false
    t.integer "node_id",      null: false
    t.string  "hostname",     null: false
    t.integer "public_ip",    null: false
    t.integer "private_ip",   null: false
    t.string  "protocol",     null: false
    t.integer "port_in",      null: false
    t.integer "port_out",     null: false
    t.string  "env_settings", null: false
    t.integer "service_id",   null: false
    t.integer "container_id", null: false
    t.index ["cluster_id"], name: "cluster_id", using: :btree
    t.index ["container_id"], name: "container_id", using: :btree
    t.index ["node_id"], name: "node_id", using: :btree
    t.index ["service_id"], name: "service_id", using: :btree
  end

  create_table "cluster_services", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string  "name",                             null: false
    t.string  "title"
    t.integer "library_service_id"
    t.integer "application_id",                   null: false
    t.integer "status",             limit: 1,     null: false
    t.integer "container_id",                     null: false
    t.integer "cluster_id",                       null: false
    t.integer "node_id"
    t.string  "hostname"
    t.string  "public_ip"
    t.string  "private_ip"
    t.string  "url"
    t.string  "protocol"
    t.integer "port_in"
    t.integer "port_out"
    t.text    "settings",           limit: 65535
    t.string  "type_name"
    t.index ["application_id"], name: "application_id", using: :btree
  end

  create_table "cluster_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string  "name",                   null: false
    t.string  "title",                  null: false
    t.boolean "enabled", default: true, null: false
    t.integer "pos",     default: 0,    null: false
    t.index ["id"], name: "id", unique: true, using: :btree
    t.index ["name"], name: "name", unique: true, using: :btree
  end

  create_table "clusters", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string  "uid",                                                null: false
    t.string  "name"
    t.string  "domainname"
    t.string  "title"
    t.integer "team_id",                                            null: false
    t.integer "primary_admin_user_id"
    t.integer "status",                limit: 1,     default: 0,    null: false
    t.integer "cluster_type_id",                     default: 0
    t.integer "hadoop_type_id",                      default: 1,    null: false
    t.integer "hadoop_app_id"
    t.text    "description",           limit: 65535
    t.text    "admin_notes",           limit: 65535
    t.boolean "is_public",                           default: true, null: false
    t.integer "last_node_number",                    default: 0,    null: false
    t.text    "options",               limit: 65535
    t.index ["domainname"], name: "systemname", unique: true, using: :btree
    t.index ["name"], name: "name", unique: true, using: :btree
    t.index ["primary_admin_user_id"], name: "primary_admin_id", using: :btree
    t.index ["team_id"], name: "team_id", using: :btree
    t.index ["uid"], name: "uid", using: :btree
  end

  create_table "cms_languages", unsigned: true, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string  "title",     limit: 250
    t.string  "lang",      limit: 4
    t.boolean "enabled",               default: true,              null: false, unsigned: true
    t.string  "charset",   limit: 15,  default: "utf8_unicode_ci", null: false
    t.string  "locale",                                            null: false
    t.string  "lang_html", limit: 10,                              null: false
    t.integer "pos",                                               null: false
    t.string  "countries",                                         null: false
    t.index ["lang"], name: "idxLang", unique: true, using: :btree
  end

  create_table "cms_mediafiles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer  "media_type"
    t.string   "path"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
  end

  create_table "cms_pages", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci PACK_KEYS=0" do |t|
    t.string   "title",                                       null: false
    t.string   "name"
    t.string   "url"
    t.integer  "url_parts_count",   limit: 1, default: 0,     null: false, unsigned: true
    t.integer  "url_vars_count",    limit: 1, default: 0,     null: false, unsigned: true
    t.string   "parsed_url"
    t.integer  "parent_id",                   default: 0,     null: false
    t.string   "view_path"
    t.boolean  "is_translated",               default: false, null: false, unsigned: true
    t.integer  "status",                      default: 0,     null: false
    t.integer  "pos",                         default: 0,     null: false
    t.string   "redir_url"
    t.integer  "template_id"
    t.integer  "layout_id"
    t.integer  "owner"
    t.boolean  "is_folder",                   default: false, null: false, unsigned: true
    t.string   "controller_action"
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.integer  "enabled",           limit: 1, default: 1,     null: false, unsigned: true
    t.index ["name"], name: "index_cms_pages_on_name", using: :btree
    t.index ["parent_id"], name: "parent_id", using: :btree
    t.index ["status"], name: "status", using: :btree
    t.index ["url"], name: "url", using: :btree
  end

  create_table "cms_pages_translation", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci PACK_KEYS=0" do |t|
    t.integer "item_id",                         default: 0, null: false, unsigned: true
    t.integer "page_id"
    t.string  "lang",              limit: 5,                 null: false
    t.string  "meta_title"
    t.text    "meta_description",  limit: 65535
    t.string  "meta_keywords"
    t.string  "template_filename"
    t.index ["item_id"], name: "item_id", using: :btree
    t.index ["lang"], name: "lang", using: :btree
    t.index ["template_filename"], name: "template", using: :btree
  end

  create_table "cms_templates", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci PACK_KEYS=0" do |t|
    t.string   "title",                                   null: false
    t.string   "name"
    t.string   "basename",                                null: false
    t.string   "basepath",                                null: false
    t.string   "basedirpath",                             null: false
    t.integer  "type_id",       limit: 1
    t.string   "tpl_format"
    t.integer  "pos"
    t.boolean  "is_translated",           default: false, null: false, unsigned: true
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.boolean  "is_folder",               default: false, null: false
    t.boolean  "enabled",                 default: true,  null: false, unsigned: true
    t.string   "ancestry"
    t.index ["ancestry"], name: "ancestry", using: :btree
    t.index ["basepath"], name: "basepath", using: :btree
    t.index ["pos"], name: "pos", using: :btree
  end

  create_table "cms_templates_translation", unsigned: true, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "item_id",           null: false, unsigned: true
    t.string  "lang",    limit: 5, null: false
    t.index ["item_id", "lang"], name: "item_id", unique: true, using: :btree
  end

  create_table "cms_templatetypes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string  "name"
    t.string  "title"
    t.integer "pos",   null: false
  end

  create_table "cms_users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["email"], name: "index_optimacms_cms_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_optimacms_cms_users_on_reset_password_token", unique: true, using: :btree
  end

  create_table "dashboards", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "cluster_id",                null: false
    t.integer "user_id"
    t.string  "name",                      null: false
    t.string  "title"
    t.boolean "enabled",    default: true, null: false
    t.integer "pos",        default: 0,    null: false
    t.index ["cluster_id"], name: "cluster_id", using: :btree
    t.index ["user_id"], name: "user_id", using: :btree
  end

  create_table "errors", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string "name",                      null: false
    t.string "title",                     null: false
    t.string "category"
    t.text   "description", limit: 65535
    t.index ["name"], name: "name", unique: true, using: :btree
  end

  create_table "groups", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string  "name",                   null: false
    t.string  "title",                  null: false
    t.boolean "enabled", default: true, null: false
  end

  create_table "instances", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "uid",                        null: false
    t.text     "admin_notes",  limit: 65535
    t.text     "sysinfo",      limit: 65535
    t.text     "data",         limit: 65535
    t.integer  "last_node_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["uid"], name: "uid", using: :btree
  end

  create_table "invitations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "uid",                         null: false
    t.integer  "from_user_id"
    t.integer  "team_id"
    t.integer  "cluster_id"
    t.string   "to_email",                    null: false
    t.integer  "status",                      null: false
    t.integer  "invitation_type", default: 0, null: false
    t.datetime "activated_at"
    t.datetime "created_at",                  null: false
    t.index ["from_user_id"], name: "user_id", using: :btree
    t.index ["team_id"], name: "cluster_id", using: :btree
    t.index ["uid"], name: "uid", unique: true, using: :btree
  end

  create_table "key_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "name"
    t.text     "fields",     limit: 65535
  end

  create_table "keys", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "uid"
    t.string   "name"
    t.integer  "user_id"
    t.text     "creds",      limit: 65535
    t.string   "key_type"
    t.index ["user_id"], name: "index_keys_on_user_id", using: :btree
  end

  create_table "library_application_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "name"
  end

  create_table "library_applications", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "name",                                                     null: false
    t.string   "title",                                                    null: false
    t.string   "git_repo"
    t.string   "description"
    t.string   "picture_file_name"
    t.string   "picture_content_type"
    t.integer  "picture_file_size"
    t.datetime "picture_updated_at"
    t.string   "category_title"
    t.string   "company_name",                                             null: false
    t.boolean  "enabled",                                   default: true, null: false
    t.integer  "pos",                                       default: 0,    null: false
    t.string   "color"
    t.text     "metadata",                    limit: 65535
    t.datetime "release_date"
    t.string   "icon_file_name"
    t.string   "icon_content_type"
    t.integer  "icon_file_size"
    t.datetime "icon_updated_at"
    t.integer  "status"
    t.integer  "library_application_type_id"
    t.index ["library_application_type_id"], name: "index_library_applications_on_library_application_type_id", using: :btree
    t.index ["name"], name: "name", unique: true, using: :btree
  end

  create_table "library_service_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "library_services", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string  "name",                                   null: false
    t.string  "title",                                  null: false
    t.string  "description"
    t.boolean "enabled",                 default: true, null: false
    t.integer "pos",                     default: 0,    null: false
    t.integer "library_service_type_id"
    t.index ["library_service_type_id"], name: "index_library_services_on_library_service_type_id", using: :btree
    t.index ["name"], name: "name", unique: true, using: :btree
  end

  create_table "message_dialogs", id: :bigint, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer  "from_user_id",    null: false
    t.integer  "to_user_id",      null: false
    t.integer  "last_message_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.index ["created_at"], name: "created_at", using: :btree
    t.index ["from_user_id"], name: "from_user_id", using: :btree
    t.index ["to_user_id"], name: "to_user_id", using: :btree
    t.index ["updated_at"], name: "updated_at", using: :btree
  end

  create_table "messages", id: :bigint, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer  "dialog_id",                              null: false
    t.integer  "from_user_id",                           null: false
    t.integer  "to_user_id",                             null: false
    t.datetime "created_at",                             null: false
    t.integer  "status",       limit: 1,     default: 1, null: false
    t.text     "message",      limit: 65535,             null: false
    t.index ["from_user_id", "to_user_id"], name: "from_user_id", using: :btree
  end

  create_table "node_host_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string  "name",                   null: false
    t.string  "title",                  null: false
    t.boolean "enabled", default: true, null: false
  end

  create_table "nodes", id: :bigint, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "uid",                                          null: false
    t.string   "name"
    t.string   "title"
    t.integer  "cluster_id",                                   null: false
    t.integer  "node_number",                  default: 0,     null: false
    t.integer  "host_type_id",                 default: 1,     null: false
    t.integer  "instance_id"
    t.boolean  "is_master",                    default: false, null: false
    t.string   "ip"
    t.integer  "port",                         default: 0,     null: false
    t.integer  "agent_port"
    t.string   "agent_token"
    t.integer  "status",         limit: 1,     default: 0,     null: false
    t.text     "system_info",    limit: 65535,                 null: false
    t.bigint   "status_changed"
    t.string   "options"
    t.string   "env_settings"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.text     "jobs_state",     limit: 65535
    t.integer  "hadoop_app_id"
    t.index ["agent_token"], name: "agent_token", using: :btree
    t.index ["cluster_id"], name: "cluster_id", using: :btree
    t.index ["name"], name: "name", using: :btree
    t.index ["status"], name: "status", using: :btree
    t.index ["uid"], name: "uid", using: :btree
  end

  create_table "options", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string  "name",                                     null: false
    t.string  "title",                                    null: false
    t.string  "option_type"
    t.text    "description", limit: 65535
    t.boolean "is_changed",                default: true, null: false
    t.string  "category"
    t.string  "value"
    t.index ["name"], name: "index_options_on_name", unique: true, using: :btree
  end

  create_table "packages", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string  "name",                     null: false
    t.string  "command_name",             null: false
    t.string  "v",                        null: false
    t.integer "status",       default: 1, null: false
    t.index ["name"], name: "name", using: :btree
  end

  create_table "services", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.integer "cluster_id", null: false
    t.integer "package_id", null: false
    t.integer "ssh_port",   null: false
  end

  create_table "teams", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "name",                                            null: false
    t.string   "uid",                                             null: false
    t.integer  "status",                limit: 1,     default: 1, null: false
    t.text     "about",                 limit: 65535
    t.integer  "primary_admin_user_id"
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.index ["created_at"], name: "created_at", using: :btree
    t.index ["name"], name: "name", unique: true, using: :btree
    t.index ["primary_admin_user_id"], name: "primary_admin_user_id", using: :btree
    t.index ["uid"], name: "uid", unique: true, using: :btree
    t.index ["uid"], name: "uid_2", unique: true, using: :btree
    t.index ["updated_at"], name: "updated_at", using: :btree
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
    t.string   "username",                                          null: false
    t.string   "email",                                             null: false
    t.string   "encrypted_password",                   default: "", null: false
    t.integer  "status",                 limit: 1,     default: 0,  null: false
    t.integer  "team_id",                                           null: false
    t.integer  "group_id",                                          null: false
    t.string   "firstname",                                         null: false
    t.string   "lastname",                                          null: false
    t.text     "about",                  limit: 65535
    t.text     "admin_notes",            limit: 65535
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                        default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "failed_attempts",                      default: 0,  null: false
    t.string   "unlock_token"
    t.datetime "sms_was_sent"
    t.datetime "locked_at"
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.integer  "invitation_id"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.text     "registration_options",   limit: 65535
    t.string   "phone_number"
    t.string   "registration_ip"
    t.string   "country"
    t.text     "customer_info",          limit: 65535
    t.datetime "customer_info_updated"
    t.index ["email"], name: "email", using: :btree
    t.index ["group_id"], name: "group_id", using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
    t.index ["team_id"], name: "team_id", using: :btree
    t.index ["username"], name: "username", using: :btree
  end

  add_foreign_key "aws_region_instance_types", "aws_instance_types"
  add_foreign_key "aws_region_instance_types", "aws_regions"
  add_foreign_key "keys", "users"
  add_foreign_key "library_applications", "library_application_types"
  add_foreign_key "library_services", "library_service_types"
end
