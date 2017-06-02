require "hashie"
require "sinatra"
require "instagram"

class INSTA
  include SharedMethods

  def initialize(post, created_time)
    @post = post
    @created_time = created_time
  end

  def created_time
    DateTime.strptime(@created_time,'%s')
  end

  def self.new_connection
    Instagram.configure do |config|
      config.client_id = ENV['INSTAGRAM_ID']
      config.client_secret = ENV['INSTAGRAM_SECRET']
      config.access_token = ENV['INSTAGRAM_TOKEN']
    end
  end

  def self.get(meth, username, amount)
    posts_INSTA = []

    INSTA.new_connection

    posts_INSTA = INSTA.method(meth).call(username, amount)

    # Hashie to Hash for standardization access
    posts_INSTA_H = posts_INSTA.map{ |post| post.to_hash }

    return posts_INSTA_H.map{ |post| INSTA.new(post, post['created_time']) }
  end

  def self.user_recent_media(username, count)
    Instagram.user_recent_media(username, {:count => count})
  end


  def standardize
    puts @post['id']
    post = Hash.new

    post['social_network'] = 'instagram'

    post['photo'] = photo if has_photo?
    post['video'] = video if has_video?

    post['message'] = parse_message(@post['caption']['text']) if has_message?
    post['user'] = user_info
    post['meta'] = meta_info

    return post
  end

  # Photo

  def has_photo?
    @post['type'] == 'image'
  end

  def photo
    data = @post['images']['standard_resolution'] # available: low_resolution, thumbnail, standard_resolution

    photo = Hash.new
    photo['width'] = data['width'].to_i
    photo['height'] = data['height'].to_i
    photo['format'] = photo_format(photo['width'], photo['height'])
    photo['src'] = data['url']
    photo['src_full'] = data['url']

    return photo
  end

  # Video

  def has_video?
    @post['type'] == 'video'
  end

  def video
    data = @post['videos']['standard_resolution'] # available: low_resolution, thumbnail, standard_resolution

    video = Hash.new
    video['provider'] = 'instagram'
    video['source'] = data['url']
    video['link'] = @post['link']
    video['picture'] = @post['images']['standard_resolution']['url']

    return video
  end

  # Message

  def has_message?
    defined?(@post['caption']['text'])
  end

  def parse_message(text="")
    text = text.gsub(/(http|https):\/\/t.co[a-z0-9._\/-]+$/i,'') # Remove the tweet's url included in the text at the end
    text = text.gsub(/(http|https):\/\/[a-z0-9._\/-]+/i, '<a href="\0">\0</a>')
    text = text.gsub(/@([a-z0-9âãäåæçèéêëìíîïðñòóôõøùúûüýþÿı_]+)/i, '<a class="mention" href="https://www.instagram.com/\1">@\1</a>')
    text = text.gsub(/\#([a-z0-9âãäåæçèéêëìíîïðñòóôõøùúûüýþÿı_-]+)/i, '<a class="hashtag" href="https://www.instagram.com/explore/tags/\1">#\1</a>')
    return text
  end

    # Infos

  def user_info
    user = Hash.new
    user['username'] = @post['user']['username']
    user['profile_image'] = @post['user']['profile_picture']
    user['url'] = "https://www.instagram.com/#{user['username']}"
    user['name'] = @post['user']['full_name']

    return user
  end

  def meta_info
    meta = Hash.new

    meta['permalink'] = @post['link']
    meta['share_url'] = @post['link']
    meta['created_time'] = "#{created_time}"

    return meta
  end

end