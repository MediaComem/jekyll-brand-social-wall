require_relative 'shared_methods.rb'
require 'koala'
require 'fileutils'
require 'mini_magick'
require "net/http"
require 'uri'

class FB
  include SharedMethods

  def initialize(post, created_time)
    @post = post
    @created_time = created_time
  end

  def created_time
    DateTime.parse(@created_time)
  end

  def self.new_connection
    @graph = Koala::Facebook::API.new(ENV['FACEBOOK_ACCESS_TOKEN'])
  end

  def self.get(meth, username, amount)
    posts_FB = []

    FB.new_connection

    posts_FB = FB.method(meth).call(username, amount)

    return posts_FB.map{ |post| FB.new(post, post['created_time']) }
  end

  def self.connections(username, count)
    @graph.get_connections(username,'posts',{limit: count})
  end

  def self.get_object(object)
    @graph.get_object(object)
  end

  # Get picture with the following standard size: thumbnail, album, normal
  # Don't return width & height data
  def self.get_picture_data(object_id, size)
    @graph.get_picture_data(object_id, 'type' => size)
  end



  def standardize
    puts @post['id']
    post = Hash.new

    post['social_network'] = 'facebook'


    post['photo'] = photo if has_photo?
    post['video'] = video if has_video?

    post['ext_quote'] = ext_quote if has_ext_quote?

    post['message'] = parse_message(@post['message']) if has_message?
    post['user'] = user_info
    post['meta'] = meta_info

    return post
  end



  # Photo

  def has_photo?
    @post['type'] == 'photo'
  end

  def photo
    data = FB.get_object(@post['object_id'])
    src_full = FB.get_picture_data(@post['object_id'], 'normal')['data']['url']

    photo = Hash.new
    photo['width'] = data['width'].to_i
    photo['height'] = data['height'].to_i
    photo['format'] = photo_format(photo['width'], photo['height'])
    photo['src'] = data['source']
    photo['src_full'] = src_full

    return photo
  end

  # Video

  def has_video?
    @post['type'] == 'video'
  end

  def video
    video = Hash.new
    video['provider'] = get_video_provider(@post['source'])
    video['source'] = parse_video(@post['source'])
    video['link'] = @post['link']
    video['picture'] = @post['picture']

    return video
  end

  # Quote

  def has_ext_quote?
    @post['type'] == 'link' && @post['status_type'] == 'shared_story'
  end

  def has_ext_quote_picture?
    @post.has_key?('picture') && @post['picture'] != '' && url_exist?(parse_ext_quote_picture(@post['picture']))
  end

  def parse_ext_quote_picture(link)
    link_parsed = CGI.parse(URI.parse(link).query)
    return link_parsed.has_key?("url") ? link_parsed["url"][0] : link
  end

  def ext_quote_picture_resize(image_url)
    image = MiniMagick::Image.open(image_url)
    if image.type == 'PNG'
      image.combine_options do |c|

        c.background '#FFFFFF' # for transparent png
        c.alpha 'remove'
      end
    end
    image.resize "300x300>" # proportional, only if larger
    image.format 'jpg'
    image.write("_site/images/social_wall/#{@post['id']}.jpg")
  end

  def ext_quote_picture
    create_path('_site/images/social_wall') if !path_exist?('_site/images/social_wall')

    image_url = parse_ext_quote_picture(@post['picture'])
    ext_quote_picture_resize(image_url)

    return "/images/social_wall/#{@post['id']}.jpg"
  end

  def ext_quote
    quote = Hash.new
    quote['link'] = @post['link']
    quote['picture'] = ext_quote_picture if has_ext_quote_picture?
    quote['source'] = @post['caption']
    quote['title'] = @post['name']
    quote['description'] = @post['description']

    return quote
  end

  def has_message_tags?
    @post.has_key?('message_tags')
  end

  # Message

  def has_message?
    @post.has_key?('message')
  end

  def parse_message(text="")
    # links
    text = text.gsub(/(http|https):\/\/[a-z0-9._\/-]+/i, '<a href="\0">\0</a>')
    # Hashtags
    text = text.gsub(/\#([a-z0-9âãäåæçèéêëìíîïðñòóôõøùúûüýþÿı_-]+)/i, '<a class="hashtag" href="https://www.facebook.com/hashtag/\1">#\1</a>')
    # Page, Group, user
    if has_message_tags?

      @post['message_tags'].each do |k, v|
        v.each do |h|
          text = text.gsub(/#{h["name"]}/, "<a class='mention' href='https://www.facebook.com/#{h["id"]}'>#{h["name"]}</a>")
        end
      end
    end

    return text
  end

  # Infos

  def user_info
    username = FB.get_object(@post['from']['id'])['username']
    picture = FB.get_picture_data(@post['from']['id'], 'normal')

    user = Hash.new
    user['username'] = username
    user['profile_image'] = picture['data']['url']
    user['url'] = "https://www.facebook.com/#{username}"
    user['name'] = @post['from']['name']

    return user
  end

  def meta_info
    meta = Hash.new
    status_id = @post['id'].split('_')

    meta['permalink'] = "http://www.facebook.com/permalink.php?story_fbid=#{status_id[1]}&id=#{status_id[0]}"
    meta['share_url'] = CGI.escape(@post['link'].to_s)
    meta['created_time'] = "#{created_time}"

    return meta
  end

end
