require_relative 'shared_methods.rb'
require 'twitter'
require 'metainspector'
require 'resolv'

class TW
  include SharedMethods

  def initialize(post, created_time)
    @post = post
    @created_time = created_time
  end

  def created_time
    DateTime.parse(@created_time)
  end

  def self.new_connection
    @clientTW = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = ENV['TWITTER_OAUTH_TOKEN']
      config.access_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET']
    end
  end

  def self.get(meth, username, include_rts, amount)
    posts_TW = []

    TW.new_connection

    posts_TW = TW.method(meth).call(username, include_rts, amount.to_i)

    return posts_TW.map{ |post| TW.new(post, post[:created_at])}
  end

  def self.hashtag_timeline(hashtag)
    return @clientTW.search(hashtag + " -rt").first
  end

  # Recursive call to match the real number of tweets with the user's input -> in user_timeline number of tweets are counted before others filters like include_rts or exclude_replies
  def self.user_timeline(username, include_rts, count, count_diff=count)
    posts_TW = @clientTW
          .user_timeline(username,{
              :include_rts => include_rts,
              :tweet_mode => 'extended',
              :exclude_replies => true,
              :count => count_diff })
          .map(&:attrs) #also known as: to_h
    return count > posts_TW.length ? user_timeline(username, include_rts, count, count_diff += count - posts_TW.length) : posts_TW
  end

  def has_type?
    !defined?(@post[:extended_entities][:media][0][:type]) && !has_quoted_status? && !has_link?
  end



  def standardize
    puts @post[:id]
    post = Hash.new

    post['social_network'] = 'twitter'

    post['photo'] = photo_instagram if has_photo_instagram?
    post['photo'] = photo(:small) if has_photo? && (!has_ext_quote? || is_ext_quote_facebook?)
    post['video'] = video if has_video?

    post['video'] = ext_quote_video if has_ext_quote? && has_ext_quote_video?

    post['int_quote'] = int_quote if has_int_quote?
    post['ext_quote'] = ext_quote if has_ext_quote? && !has_ext_quote_video? && !is_ext_quote_facebook?

    post['message'] = parse_message(@post[:full_text]) if has_message?

    post['user'] = user_info
    post['meta'] = meta_info

    return post
  end



  def text_only?
    !defined?(@post[:extended_entities][:media][0][:type]) && !has_quoted_status? && !has_link?
  end

  # Photos

  def has_photo?
    defined?(@post[:extended_entities][:media][0][:type]) && @post[:extended_entities][:media][0][:type] == "photo"
  end

  # @params size: thumb, small, medium, large
  def photo(size)
    data = @post[:extended_entities][:media][0]
    photo = Hash.new
    photo['width'] = data[:sizes][size][:w].to_i
    photo['height'] = data[:sizes][size][:h].to_i
    photo['format'] = photo_format(photo['width'], photo['height'])
    photo['src'] = data[:media_url_https] + ":#{size}"
    photo['src_full'] = data[:media_url_https]

    return photo
  end

  def has_photo_instagram?
    defined?(@post[:entities][:urls][0][:expanded_url]) && MetaInspector.new(@post[:entities][:urls][0][:expanded_url]).host =~ /www.instagram.com/
  end

  def photo_instagram
    photo = Hash.new
    photo['src'] = photo['src_full'] = get_url_best_picture(@post[:entities][:urls][0][:expanded_url])

    return photo
  end

  # video

  def has_video?
    defined?(@post[:extended_entities][:media][0][:type]) && @post[:extended_entities][:media][0][:type] == "video"
  end

  def video
    variants = @post[:extended_entities][:media][0][:video_info][:variants]
    selected_video = variants.select {|item| item[:content_type] == "video/mp4"}
                   .max_by{|item| item[:bitrate]}

    video = Hash.new
    video['provider'] = 'twitter'
    video['source'] = parse_video(selected_video[:url])

    video['picture'] = @post[:extended_entities][:media][0][:media_url_https]

    return video
  end

  # Quote
  # Internal: inside twitter, external: only link - Twitter doesn't fetch for us (everytime) the infos (picture, title, description...)

  def has_int_quote?
    @post.has_key?(:is_quote_status) && @post[:is_quote_status] == true
  end

  def has_int_quote_photo?
    defined?(@post[:quoted_status][:extended_entities][:media][0][:media_url_https]) && @post[:quoted_status][:extended_entities][:media][0][:type] == 'photo'
  end

  def int_quote
    quote = Hash.new
    quote['link'] = @post[:entities][:urls][0][:expanded_url] # Get the last url (usually the twitter status)
    quote['picture'] = has_int_quote_photo? ? "#{@post[:quoted_status][:extended_entities][:media][0][:media_url_https]}:small" : get_url_best_picture(quote['link'])
    quote['source'] = @post[:quoted_status][:user][:screen_name]
    quote['title'] = @post[:quoted_status][:user][:name]
    quote['description'] = parse_message(@post[:quoted_status][:full_text])

    return quote

  end

  def has_ext_quote?
    !@post.has_key?(:is_quote_status) && @post[:is_quote_status] != true && defined?(@post[:entities][:urls][0][:expanded_url]) # if expanded_url doesn't exist it means that the shared tweet is not available anymore
  end

  def has_ext_quote_video?
    !get_video_provider(@post[:entities][:urls][0][:expanded_url]).empty?
  end

  def is_ext_quote_facebook? # Can't fetch facebook page without login (captcha asked)
    MetaInspector.new(@post[:entities][:urls][0][:expanded_url]).host =~ /www.facebook.com/
  end

  def ext_quote_video
    video = Hash.new
    video['provider'] = get_video_provider(@post[:entities][:urls][0][:expanded_url])
    video['source'] = parse_video(get_deep_link(@post[:entities][:urls][0][:expanded_url]))

    return video
  end

  def ext_quote
    page = MetaInspector.new(@post[:entities][:urls][0][:expanded_url])
    quote = Hash.new
    quote['link'] = @post[:entities][:urls][0][:expanded_url]

    # Use the fetched Twitter picture if existing
    quote['picture'] = has_photo? ? @post[:extended_entities][:media][0][:media_url_https] + ":small" : page.images.best

    quote['source'] = page.host
    quote['title'] = page.best_title
    quote['description'] = page.best_description

    return quote

  end

  # Message

  def has_message?
    @post.has_key?(:full_text)
  end

  def parse_message(text="")
    text = text.gsub(/(http|https):\/\/t.co[a-z0-9._\/-]+$/i,'') # Remove the tweet's url included in the text at the end
    text = text.gsub(/(http|https):\/\/[a-z0-9._\/-]+/i, '<a href="\0">\0</a>')
    text = text.gsub(/@([a-z0-9âãäåæçèéêëìíîïðñòóôõøùúûüýþÿı_]+)/i, '<a class="mention" href="http://twitter.com/\1">@\1</a>')
    text = text.gsub(/\#([a-z0-9âãäåæçèéêëìíîïðñòóôõøùúûüýþÿı_-]+)/i, '<a class="hashtag" href="http://twitter.com/search?q=%23\1">#\1</a>')
    return text
  end

  # Infos

  def parse_profile_image(link)
    return link.gsub('_normal', '') # Remove size attribute at the end to get the biggest image
  end

  def user_info
    user = Hash.new
    user['username'] = @post[:user][:screen_name]
    user['profile_image'] = parse_profile_image(@post[:user][:profile_image_url_https])
    user['url'] = "http://twitter.com/#{@post[:user][:screen_name]}"
    user['name'] = @post[:user][:name]

    return user
  end

  def meta_info
    meta = Hash.new
    meta['permalink'] = "http://twitter.com/#{@post[:user][:screen_name]}/status/#{@post[:id_str]}"
    meta['share_url'] = @post[:id_str]
    meta['created_time'] = "#{created_time}"

    return meta
  end

end
