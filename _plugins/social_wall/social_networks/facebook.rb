require 'koala'

class FB

  def initialize(post, created_time)
    @post = post
    @created_time = created_time
  end

  def created_time
    DateTime.parse(@created_time).change(:offset => "-0800")
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

  def self.get_object(object)
    return Tools.transform_keys_to_symbols(@graph.get_object(object))
  end

  def self.get_picture_data(object_id, size)
    return Tools.transform_keys_to_symbols(@graph.get_picture_data(object_id, :type => size))
  end

  def render
    html = String.new

    if post_valid?
      html << "<div class='facebook_status #{@post[:type]}'>"
      html << photo if has_photo?
      html << video if has_video?
      html << message
      html << shared_story if has_shared_story?
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

  def photo
    picture_url = FB.get_picture_data(@post[:object_id], 'normal')[:data][:url] # must be one of the following values: thumbnail, album, normal

    return  <<-CODE
      <a href="#{picture_url}" class="link-photo" title="#{@post[:message].truncate(70)}">
        <img src="#{picture_url}"/>
      </a>
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
        <iframe src="#{parse_video(@post[:source])}" autoplay="0" frameborder="0" badge="0" portrait="0" byline="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>
      CODE
    end
  end

  def parse_video(lien)
    # Remove autoplay
    lien.gsub('autoplay=1', 'autoplay=0')
    return lien
  end

  def message
    <<-CODE
      <p class="status">#{parse_message(@post[:message])}</p>
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
        <h2>#{@post[:name]}</h2>
        <p class="desc">#{@post[:description]}</p>
        <cite>#{@post[:caption]}</cite>
      </blockquote>
    CODE
  end

  def meta_info
    <<-CODE
      <p class="info">
        <span class="icon">f</span>
        <span class="user"><a href="https://www.facebook.com/#{@post[:from][:name]}">#{@post[:from][:name]}</a></span>
        <time pubdate datetime="#{created_time}">#{created_time}</time>
        <a class="share icon" href="http://www.facebook.com/share.php?v=4&amp;src=bm&amp;u=#{CGI.escape(@post[:link])}">i</a>
      </p>
    CODE
  end

end
