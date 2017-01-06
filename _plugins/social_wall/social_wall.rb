require 'dotenv'
require_relative 'class_extend'
require_relative 'social_networks/TW'
require_relative 'social_networks/FB'

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
      html = ""

      # Get the Facebook FEEDS

      if @config.key?('fb_username')
        postsFB = FB.get_posts(@config['fb_username'], @config['fb_limit'])
      end

      # Get the Twitter TIMELINE

      if @config.key?('tw_username')
        postsTW = TW.get_tweets(@config['tw_username'], @config['tw_include_rts'], @config['tw_limit'])
      end
      
      # Merge and sort the Hashes of posts by date
      allposts = (postsFB << postsTW).flatten!.sort_by { |hsh| Date.parse(hsh[:created_time]) }.reverse!

      # Mix and add HTML For each post
      allposts.each do |post|
        # Facebook
        if post.key?(:likes)
          html << FB.template(post)
        end
        # Twitter
        if post.key?(:retweeted)
          html << TW.template(post)
        end
      end

      "<div id='social_wall'>#{html}</div>"
    end
  end
end

Liquid::Template.register_tag('social_wall', Jekyll::SocialWall)
