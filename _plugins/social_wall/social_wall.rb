require 'dotenv'
require_relative 'social_networks/twitter'
require_relative 'social_networks/facebook'
require_relative 'social_networks/instagram'

module Jekyll

  class SocialWall < Liquid::Tag

    def initialize(tag_name, config, token)
      super
      Dotenv.load

      # Config from Liquid.:Tag
      @config = parse_liquid_params(config)

      @config['tw_include_rts']   ||= false
      @config['fb_amount']        ||= 10
      @config['tw_amount']        ||= 10
      @config['insta_amount']        ||= 10

      @layout = Liquid::Template.parse(
                    File.read("_layouts/social_wall.html").chomp
                  )
    end

    def parse_liquid_params(params)
        attributes = {}
        params.scan(::Liquid::TagAttributes) do |key, value|
          attributes[key] = value
        end
        return attributes
    end

    def has_facebook_settings?
      @config.key?('fb_username')
    end

    def facebook_posts
      return FB.get(:connections, @config['fb_username'], @config['fb_amount']) if has_facebook_settings?
      []
    end

    def has_twitter_settings?
      @config.key?('tw_username')
    end

    def twitter_posts
      return TW.get(:user_timeline, @config['tw_username'], @config['tw_include_rts'], @config['tw_amount']) if has_twitter_settings?
      []
    end

    def has_instagram_settings?
      @config.key?('insta_username')
    end

    def instagram_posts
      return INSTA.get(:user_recent_media, @config['insta_username'], @config['insta_amount']) if has_instagram_settings?
      []
    end

    def mix_posts
      mix_posts = []

      mix_posts += facebook_posts
      mix_posts += twitter_posts
      mix_posts += instagram_posts

      mix_posts
        .sort_by { |post| post.created_time }
        .reverse
    end

    def render(context)
      mix_posts.map{ |post| @layout.render(post.standardize)}.join || ""
    end

  end

end

Liquid::Template.register_tag('social_wall', Jekyll::SocialWall)
