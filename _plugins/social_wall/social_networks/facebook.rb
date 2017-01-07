require 'koala'

class FB

  def self.get_posts(username, limit=10)
    @graph = Koala::Facebook::API.new(ENV['FACEBOOK_ACCESS_TOKEN'], ENV['FACEBOOK_SECRET'])
    return Tools.transform_keys_to_symbols(@graph.get_connections(username,'posts',{limit: limit}))
  end

  def self.get_object(object)
    @graph = Koala::Facebook::API.new(ENV['FACEBOOK_ACCESS_TOKEN'], ENV['FACEBOOK_SECRET'])
    return Tools.transform_keys_to_symbols(@graph.get_object(object))
  end

  def self.get_picture_data(object_id, size)
    @graph = Koala::Facebook::API.new(ENV['FACEBOOK_ACCESS_TOKEN'], ENV['FACEBOOK_SECRET'])
    return Tools.transform_keys_to_symbols(@graph.get_picture_data(object_id, :type => size))
  end

  def self.parse_post(text)
    text = text.gsub(/http[s]:\/\/[a-z0-9._\/-]+/i, '<a href="\0">\0</a>')
    text = text.gsub(/\#([a-z0-9âãäåæçèéêëìíîïðñòóôõøùúûüýþÿı_-]+)/i, '<a class="hashtag" href="https://www.facebook.com/hashtag/\1">#\1</a>')
    return text
  end

  def self.template(post)
    html = String.new

    if !post[:message].nil? && ['photo','video'].include?(post[:type]) || (post[:type] == 'link' && post[:status_type] == 'shared_story')
      case
      when post[:type] == 'link' && post[:status_type] == 'shared_story'

        html << <<-CODE

        <div class='facebook_status share'>
          <p class="status">#{self.parse_post(post[:message])}</p>
          <blockquote cite="#{post[:link]}">
            <p class="story_img"><a href="#{post[:link]}"><img src="#{post[:picture]}" border="0"></a></p>
            <h2>#{post[:name]}</h2>
            <p class="desc">#{post[:description]}</p>
          <cite>#{post[:caption]}</cite>
          </blockquote>
        CODE

      when post[:type] == 'photo'
        picture_url = self.get_picture_data(post[:object_id], 'normal')[:data][:url] # must be one of the following values: thumbnail, album, normal
        html << <<-CODE

        <div class='facebook_status photo'>
          <a href="#{picture_url}" class="btn-sm-photo" title="#{post[:message].truncate(70)}">
          <img src="#{picture_url}" border="0"></a>
          <p class="status">#{self.parse_post(post[:message])}</p>
        CODE

      when post[:type] == 'swf'
        status_id = post[:id].split('_')

        html << <<-CODE

        <div class='facebook_status swf'>
          <dl>
            <dt><a href="http://www.facebook.com/permalink.php?story_fbid=#{status_id[1]}&id=#{status_id[0]}" class="btn-sm-video"><img src=#{post[:picture]}" border="0"></a></dt>
            <dd>
              <p class="status">#{self.parse_post(post[:message])}</p>
            </dd>
          </dl>
        CODE

      when post[:type] == 'video'
        status_id = post[:id].split('_')

        html << <<-CODE

        <div class='facebook_status video'>
          <dl>
            <dt><a href="#{post[:source]}" class="btn-sm-video" title="#{post[:message].truncate(70)}"><span class="play_btn">&#9654;</span><img src=#{post[:picture]}" border="0"></a></dt>
            <dd>
              <p class="status">#{self.parse_post(post[:message])}</p>
            </dd>
          </dl>
        CODE

      else
        html = ""
      end

      html << <<-CODE
        <p class="info">
          <span class="icon">f</span>
          <span class="user"><a href="https://www.facebook.com/#{post[:from][:name]}">#{post[:from][:name]}</a></span>
          <time pubdate datetime="#{DateTime.parse(post[:created_time]).change(:offset => "-0800")}">#{DateTime.parse(post[:created_time]).change(:offset => "-0800")}</time>
          <a class="share icon" href="http://www.facebook.com/share.php?v=4&amp;src=bm&amp;u=#{CGI.escape(post[:link])}">i</a>
        </p>
      </div>
      CODE

    else
      html = ""
    end

    return html
  end

end
