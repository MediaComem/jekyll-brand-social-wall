require 'dotenv'
require_relative 'class_extend'
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
        @config = (parse_liquid_params(config)).merge(@config)
    end

    def has_facebook_settings?
        @config.key?('fb_username')
    end

    def facebook_posts
        return FB.get_posts(@config['fb_username'], @config['fb_limit']) if has_facebook_settings?
        []
    end

    def has_twitter_settings?
        @config.key?('tw_username')
    end

    def twitter_posts
        return TW.get_posts(@config['tw_username'], @config['tw_include_rts'], @config['tw_limit']) if has_twitter_settings?
        []
    end

    def mix_posts

        mix_posts = []

        mix_posts += facebook_posts
        mix_posts += twitter_posts

        mix_posts.
            flatten.
            sort_by { |hsh| Date.parse(hsh[:created_time]) }.
            reverse
    end

    def to_html(post)

        html = ""

        if post.key?(:likes)
          html << FB.template(post)
        # Twitter
        else post.key?(:retweeted)
          html << TW.template(post)
        end

        return html

    end

    def render(context)

        html = mix_posts.map{ |post| post.template}

        %Q{<div id='social_wall'>#{html}</div>}
    end

    def parse_liquid_params(params)
      attributes = {}
      params.scan(::Liquid::TagAttributes) do |key, value|
        attributes[key] = value
      end
      return attributes
    end

  end

  class post

  end

end

Liquid::Template.register_tag('social_wall', Jekyll::SocialWall)
