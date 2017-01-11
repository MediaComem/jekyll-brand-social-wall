require 'dotenv'
require_relative 'tools'
require_relative 'social_networks/twitter'
require_relative 'social_networks/facebook'

module Jekyll

  class SocialWall < Liquid::Tag

    def initialize(tag_name, config, token)
      super
      Dotenv.load

      # Config from _config.yml
      @config = Jekyll.configuration({})['social_wall'] || {}

      # Config from Liquid.:Tag
      @config = (Tools.parse_liquid_params(config)).merge(@config)

      @config['tw_include_rts'] ||= false
      @config['fb_limit']    ||= 10
      @config['tw_limit']    ||= 10
    end

    def has_facebook_settings?
      @config.key?('fb_username')
    end

    def facebook_posts
      return FB.get(:connections, @config['fb_username'], @config['fb_count']) if has_facebook_settings?
      []
    end

    def has_twitter_settings?
      @config.key?('tw_username')
    end

    def twitter_posts
      return TW.get(:user_timeline, @config['tw_username'], @config['tw_include_rts'], @config['tw_count']) if has_twitter_settings?
      []
    end

    def mix_posts
      mix_posts = []

      mix_posts += facebook_posts
      mix_posts += twitter_posts

      mix_posts
        .sort_by { |post| post.created_time }
        .reverse
    end

    def render(context)
      html = mix_posts.map{ |post| post.render}.join || ""

      %Q"<div class='social_wall'>#{html}</div>"
    end

  end

end

Liquid::Template.register_tag('social_wall', Jekyll::SocialWall)
