class Key < ApplicationRecord

  KEY_TYPES = {
      aws: {
          aws_key_id: {type: 'string', required: true, title: 'AWS Access Key ID', secret: false },
          aws_secret_key: {type: 'string', required: true, title: 'AWS Secret Access Key', secret: true }
      }
  }

  belongs_to :user


  def self.get_by_uid(uid)
    where(uid: uid).first
  end

  ###
  def creds_hash
    return @creds_hash unless @creds_hash.nil?
    return {} if self.creds.nil?

    @creds_hash = JSON.parse(self.creds) rescue {}

    @creds_hash ||= {}
    @creds_hash
  end

  def get_cred(cred_name)
    creds_hash[cred_name]
  end

  def secure_creds_hash
    secure_hash = { }

    creds_hash.each do |name, val|
      field_meta = KEY_TYPES[key_type.to_sym][name.to_sym] rescue nil
      if field_meta[:secret]
        secure_hash[name] = val.gsub(/.(?=.....)/, '*')
      else
        secure_hash[name] = val
      end
    end

    secure_hash
  end

  def to_hash
    {
        id: id,
        name: name,
        type: key_type,
        creds: creds_hash
    }
  end

  def to_hash_secure
    {
      id: id,
      name: name,
      type: key_type,
      creds: secure_creds_hash
    }
  end

end
