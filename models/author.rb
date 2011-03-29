class Author
  DEFAULT_AVATAR = "/images/avatar.png"
  GRAVATAR_HOST  = "gravatar.com"
  
  include MongoMapper::Document
  
  key :username, String
  key :name, String
  key :email, String
  key :website, String
  key :bio, String
  key :image_url, String
  key :valid_gravatar, Boolean

  one :feed
  one :user
  
 # The url of their profile page
  key :remote_url, String

  def email= x
    super(x)

    # address changed, we'll have to redo our gravatar check
    self.valid_gravatar = nil
  end

  def self.create_from_hash!(hsh)
    create!(
      :name => hsh['user_info']['name'],
      :username => hsh['user_info']['nickname'],
      :website => hsh['user_info']['urls']['Website'],
      :bio => hsh['user_info']['description'],
      :image_url => hsh['user_info']['image'],
      :remote_url => hsh['user_info']['url']
    )
  end

  def url
    return remote_url if remote_url
    "/users/#{username}"
  end

  def avatar_url
    return image_url    if image_url
    return gravatar_url if valid_gravatar?

    DEFAULT_AVATAR
  end

  def display_name
    return username if name.nil? || name.empty?
    name
  end

  # this should really be cached.
  def valid_gravatar?
    return unless email
    return valid_gravatar unless valid_gravatar.nil?

    res = begin
            Net::HTTP.start(GRAVATAR_HOST, 80) do |http|
              # Use HEAD instead of GET for SPEED!
              http.head(gravatar_path).is_a?(Net::HTTPOK)
            end
          rescue
            # No internet connection
            false
          end

    update_attributes(:valid_gravatar => res)
    res
  end

  def gravatar_url
    return DEFAULT_AVATAR if email.nil?
    "http://#{GRAVATAR_HOST}#{gravatar_path}"
  end

  def gravatar_path
    "/avatar/#{Digest::MD5.hexdigest(email)}?s=48&r=r&d=404"
  end
end
