require 'koala'

class FB

  def initialize(post, created_time)
    @post = post
    @created_time = created_time
  end

  def created_time
    DateTime.parse(@created_time)
  end

  def self.new_connection
    @graph = Koala::Facebook::API.new(ENV['FACEBOOK_ACCESS_TOKEN'], ENV['FACEBOOK_SECRET'])
  end

  def self.get(meth, username, limit)
    posts_FB = []

    FB.new_connection

    posts_FB = FB.method(meth).call(username, limit)

    return posts_FB.map{ |post| FB.new(post, post[:created_time]) }
  end

  def self.connections(username, limit)
    return Tools.transform_keys_to_symbols(@graph.get_connections(username,'posts',{limit: limit}))
  end

  def self.get_picture_data(object_id, size)
    return Tools.transform_keys_to_symbols(@graph.get_picture_data(object_id,:type => size))
  end

  def render
    html = String.new

    if post_valid?
      html << "<div class='facebook_status item #{@post[:type]}'>"
      html << photo if has_photo?
      html << video if has_video?
      html << shared_story if has_shared_story?
      html << message
      html << meta_info
      html << "</div>"
    end

    return html || ""
  end

  def post_valid?
    !@post[:message].nil? && ['photo','video'].include?(@post[:type]) || (@post[:type] == 'link' && @post[:status_type] == 'shared_story')
  end

  def has_photo?
    @post[:type] == 'photo'
  end

  def photo_format(height, width)

  end

  def parse_photo_format(lien)
    return lien.scan(/\/s([0-9]{1,4})x([0-9]{1,4})\//)
  end

  def photo
    picture = FB.get_picture_data(@post[:object_id], 'normal') # must be one of the following values: thumbnail, album, normal
    #puts picture
    #puts parse_photo_format(picture[:data][:url])
    return  <<-CODE
        <img src="#{picture[:data][:url]}" class=""/>
    CODE
  end

  def has_video?
    @post[:type] == 'video'
  end

  def is_facebook_video?
    @post[:source] =~ /^https:\/\/(video.xx.fbcdn.net|scontent.xx.fbcdn.net)/i
  end

  def video
    if is_facebook_video?
      <<-CODE
        <video controls>
          <source src="#{@post[:source]}" type="video/mp4">
          Your browser does not support the video tag.
          <a href="#{@post[:link]}"><img src="#{@post[:picture]}"/></a>
        </video>
      CODE
    else # Youtube, Dailymotion, Vimeo, more?
      <<-CODE
        <div class="wrap_iframe">
          <iframe src="#{parse_video(@post[:source])}" autoplay="0" frameborder="0" badge="0" portrait="0" byline="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>
        </div>
      CODE
    end
  end

  def parse_video(lien)
    # Youtube custom link
    lien = lien.gsub('autoplay=1', 'autoplay=0&rel=0&amp;showinfo=0')
    return lien
  end

  def message
    <<-CODE
      <div class="status_box">
        <p class="status">#{parse_message(@post[:message])}</p>
        <p class="read-more"><a href="#" class="button"></a></p>
      </div>
    CODE
  end

  def parse_message(text)
    text = text.gsub(/http[s]:\/\/[a-z0-9._\/-]+/i, '<a href="\0">\0</a>')
    text = text.gsub(/\#([a-z0-9âãäåæçèéêëìíîïðñòóôõøùúûüýþÿı_-]+)/i, '<a class="hashtag" href="https://www.facebook.com/hashtag/\1">#\1</a>')
    return text
  end

  def has_shared_story?
    @post[:type] == 'link' && @post[:status_type] == 'shared_story'
  end

  def shared_story
    <<-CODE
      <blockquote cite="#{@post[:link]}">
        <p class="story_img"><a href="#{@post[:link]}"><img src="#{@post[:picture]}"></a></p>
        <h2><a href="#{@post[:link]}">#{@post[:name]}</a></h2>
        <p class="desc">#{@post[:description].to_s.truncate(70)}</p>
        <cite>#{@post[:caption]}</cite>
      </blockquote>
    CODE
  end

  def meta_info
    <<-CODE
      <p class="info left">
        <span class="icon-facebook"></span>
        <span class="user"><a href="https://www.facebook.com/#{@post[:from][:name]}">#{@post[:from][:name]}</a></span>
      </p>
      <p class="info right">
        <time pubdate datetime="#{created_time}">#{created_time}</time>
        <a class="icon-share" href="http://www.facebook.com/share.php?v=4&amp;src=bm&amp;u=#{CGI.escape(@post[:link])}"></a>
      </p>
    CODE
  end

end
