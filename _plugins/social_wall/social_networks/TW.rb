require 'twitter'

class TW

  def self.get_tweets(username, include_rts, limit)
    postsTWformated = []
    postsTW = []

    limit = (defined?(limit)).nil? ? 10 : limit
    include_rts = (defined?(include_rts)).nil? ? false : include_rts

    clientTW = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = ENV['TWITTER_OAUTH_TOKEN']
      config.access_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET']
    end

    postsTW = clientTW.user_timeline(username,{:include_rts => include_rts,:tweet_mode => 'extended', :exclude_replies => true,:count => limit }).map(&:attrs)

    # Change symbol of :created_at to the facebook one :created_time
    for post in postsTW
      post[:created_time] = post.delete :created_at
      postsTWformated << (post)
    end

    return postsTWformated
  end

  def self.parse_tweet_text(text)
    text = text.gsub(/http[s]:\/\/t.co[a-z0-9._\/-]+$/i,'') # Twitter api serve the text including at the end the tweet's url
    text = text.gsub(/http[s]:\/\/[a-z0-9._\/-]+/i, '<a href="\0">\0</a>')
    text = text.gsub(/@([a-z0-9âãäåæçèéêëìíîïðñòóôõøùúûüýþÿı_]+)/i, '<a class="mention" href="http://twitter.com/\1">@\1</a>')
    text = text.gsub(/\#([a-z0-9âãäåæçèéêëìíîïðñòóôõøùúûüýþÿı_-]+)/i, '<a class="hashtag" href="http://twitter.com/search?q=%23\1">#\1</a>')
    return text
  end

  def self.template(tweet)
    html = String.new
    date_time = DateTime.parse(tweet[:created_time]).change(:offset => "-0800")

    html << <<-CODE

      <div class="twitter_status">
          <p class="status" id="#{tweet[:id_str]}">#{self.parse_tweet_text(tweet[:full_text])}</p>
      CODE

    # Check if a media is associated with the tweet

    if defined?(tweet[:entities][:media][0][:media_url])
      html << <<-CODE
          <img src="#{tweet[:entities][:media][0][:media_url]}:small" />
      CODE
    end

    # Shared_story - if expanded_url doesn't exist it means that the shared tweet is not available anymore

    if tweet[:is_quote_status] && defined?(tweet[:quoted_status][:entities][:urls][0][:expanded_url])
        html << <<-CODE
            <blockquote cite="#{tweet[:quoted_status][:entities][:urls][0][:expanded_url]}">
        CODE

        if defined?(tweet[:quoted_status][:entities][:media][0][:media_url])
          html << <<-CODE
                <p class="story_img">
                  <a href="#{tweet[:quoted_status][:entities][:urls][0][:expanded_url]}">
                    <img src="#{tweet[:quoted_status][:entities][:media][0][:media_url]}:thumb">
                  </a>
                </p>
          CODE
        end

        html << <<-CODE
              <h2><cite><a href="http://twitter.com/#{tweet[:quoted_status][:user][:screen_name]}">#{tweet[:quoted_status][:user][:name]}</a></cite></h2>
              <p class="desc">#{TW.parse_tweet_text(tweet[:quoted_status][:full_text])}</p>
            <cite>@#{tweet[:quoted_status][:user][:screen_name]}</cite>
            </blockquote>
        CODE
    end

    html << <<-CODE
          <p class="info">
            <span class="icon">t</span>
            <span class="user"><a href="http://twitter.com/#{tweet[:user][:screen_name]}">#{tweet[:user][:name]}</a></span>
            <time pubdate datetime="#{date_time}">#{date_time}</time>
            <a href="https://twitter.com/intent/favorite?tweet_id=#{tweet[:id_str]}" class="favorite icon">R</a>
            <a href="https://twitter.com/intent/retweet?tweet_id=#{tweet[:id_str]}" class="retweet icon">J</a>
            <a href="https://twitter.com/intent/tweet?in_reply_to=#{tweet[:id_str]}" class="tweet icon">h</a>
          </p>
      </div>

      CODE

    return html
  end

end
