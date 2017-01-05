require 'dotenv'
require 'json'
require 'koala'
require 'twitter'
require 'date'

module Jekyll

  class SocialWall < Liquid::Tag

    def initialize(tag_name, config, token)
      super

      # Config from _config.yml
      @config = Jekyll.configuration({})['social_wall'] || {}

      # Config from Liquid.:Tag
      args = config.split(/\s+/).map(&:strip)
      args.each do |arg|
        k,v = arg.split('=').map(&:strip)
        if k && v
          if v =~ /^'(.*)'$/
            v = $1
          end
          @config[k] = v
        end
      end

      # ENV variable from the file .env in the root folder
      Dotenv.load

    end

    def render(context)

      allposts = []
      postsFB = []
      postsTW = []
      postsTWformated = []
      html = ""

      # Get the Facebook FEEDS

      if @config.key?('fb_username')
        postsFB = FacebookSocial.get_posts(@config['fb_username'], @config['fb_limit'])
      end

      # Get the Twitter TIMELINE

      if @config.key?('tw_username')
        postsTW = TwitterSocial.get_posts(@config['tw_username'], @config['tw_limit'])

        # Change symbol of created_at to the facebook one
        for post in postsTW
          post[:created_time] = post.delete :created_at
          postsTWformated << (post)
        end
      end

      # Merge and sort the Hashes of posts by date
      allposts = (postsFB << postsTWformated).flatten!.sort_by { |hsh| Date.parse(hsh[:created_time]) }.reverse!

      # HTML For each post
      allposts.each do |post|
        # Facebook
        if post.key?(:likes)
          html << FacebookSocial.template(post)
        end
        # Twitter
        if post.key?(:retweeted)
          html << TwitterSocial.template(post)
        end
      end

      "<div id='social_wall'>#{html}</div>"
    end

  end

  class FacebookSocial

    def self.get_posts(username, limit)
      limit = (defined?(limit)).nil? ? 10 : limit
      @graph = Koala::Facebook::API.new(ENV['FACEBOOK_ACCESS_TOKEN'], ENV['FACEBOOK_SECRET'])
      return Tools.transform_keys_to_symbols(@graph.get_connections(username,'posts',{limit: limit}))
    end

    def self.get_object(object)
      @graph = Koala::Facebook::API.new(ENV['FACEBOOK_ACCESS_TOKEN'], ENV['FACEBOOK_SECRET'])
      return Tools.transform_keys_to_symbols(@graph.get_object(object))
    end


    def self.template(post)
      html = String.new

      if !post[:message].nil? && ['photo','video'].include?(post[:type]) || (post[:type] == 'link' && post[:status_type] == 'shared_story')
        case
        when post[:type] == 'link' && post[:status_type] == 'shared_story'

          html << <<-CODE

          <div class='link shadow'>
            <dl>
              <dt><a href="#{post[:link]}" class="btn-sm-link"><img src=#{post[:picture]}" border="0"></a></dt>
              <dd>
                <p>#{post[:message]}</p>
              </dd>
            </dl>

          CODE

        when post[:type] == 'photo'
          picture_url = self.get_object(post[:object_id])[:picture]
          html << <<-CODE

          <div class='photo shadow'>
            <a href="#{picture_url}" class="btn-sm-photo" title="#{post[:message].truncate(70)}">
            <img src="#{picture_url}" border="0"></a>
            <p>#{post[:message]}</p>

          CODE

        when post[:type] == 'swf'
          status_id = post[:id].split('_')

          html << <<-CODE

          <div class='swf shadow'>
            <dl>
              <dt><a href="http://www.facebook.com/permalink.php?story_fbid=#{status_id[1]}&id=#{status_id[0]}" class="btn-sm-video"><img src=#{post[:picture]}" border="0"></a></dt>
              <dd>
                <p>#{post[:message]}</p>
              </dd>
            </dl>

          CODE

        when post[:type] == 'video'
          status_id = post[:id].split('_')

          html << <<-CODE

          <div class='video shadow'>
            <dl>
              <dt><a href="#{post[:source]}" class="btn-sm-video" title="#{post[:message].truncate(70)}"><span class="play_btn">&#9654;</span><img src=#{post[:picture]}" border="0"></a></dt>
              <dd>
                <p>#{post[:message]}</p>
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
            <span class="date">#{Date.parse(post[:created_time])}</span>
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

  class TwitterSocial

    def self.get_posts(username, limit)
      limit = (defined?(limit)).nil? ? 10 : limit
      clientTW = Twitter::REST::Client.new do |config|
        config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
        config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
        config.access_token        = ENV['TWITTER_OAUTH_TOKEN']
        config.access_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET']
      end
      return clientTW.user_timeline(username,{:include_rts => true,:exclude_replies => true,:count => limit }).map(&:attrs)
    end

    def self.template(tweet)
      html = String.new
      
      html << <<-CODE

        <div class="twitter_status_item item" id="#{Date.parse(tweet[:created_time])}">
          <div class="shadow">
            <p class="tw_status" id="#{tweet[:id_str]}">#{tweet[:text]}</p>
            <p class="info">
              <span class="icon">t</span>
              <span class="tw_username"><a href="http://twitter.com/#{tweet[:user][:screen_name]}">#{tweet[:user][:name]}</a></span>
              <span class="tw_timestamp date">#{Date.parse(tweet[:created_time])}</span>
              <a href="https://twitter.com/intent/favorite?tweet_id=#{tweet[:id_str]}" class="favorite icon">R</a>
              <a href="https://twitter.com/intent/retweet?tweet_id=#{tweet[:id_str]}" class="retweet icon">J</a>
              <a href="https://twitter.com/intent/tweet?in_reply_to=#{tweet[:id_str]}" class="tweet icon">h</a>
            </p>
          </div>
        </div>

        CODE

      return html
    end

  end

end

class String
  def truncate(max)
    length > max ? "#{self[0...max]}..." : self
  end
end

class Tools
  # Transform Array of Hashes "id" => "123" like to :id => "123" like
  # Source: http://www.any-where.de/blog/ruby-hash-convert-string-keys-to-symbols/
  def self.transform_keys_to_symbols(value)
    if value.is_a?(Array)
      array = value.map{|x| x.is_a?(Hash) || x.is_a?(Array) ? transform_keys_to_symbols(x) : x}
      return array
    end
    if value.is_a?(Hash)
      hash = value.inject({}){|memo,(k,v)| memo[k.to_sym] = transform_keys_to_symbols(v); memo}
      return hash
    end
    return value
  end
end

Liquid::Template.register_tag('social_wall', Jekyll::SocialWall)
