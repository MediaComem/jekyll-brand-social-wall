# Jekyll Brand Social Wall :barber:
A jekyll plugin to generate a social wall with your favorite social networks

![](img_readme/render_example.png)

## What it does in 3 lines
 * Fetch your last posts from different social networks
 * Mix and sort them by date and time
 * Render HTML Markup

## Why you should use it
 * Compare to all others js plugin, it doesn't expose any of your credentials
 * No need of realtime update if yours social accounts have no more than few news every day
 * Lightweight and cacheable

## The Social Wall Definition

A **social wall** is a posts aggregator from multiple social networks. It combines them, display them and give to the public an insight of the social activity and the latest news of a brand.

Synonyms: Social.... Flow, Feeds, Board, Stream, Wall, Cards, Hub, Media Aggregator, Network wall, Tagboard

### Various layouts

[![](img_readme/social_wall-1c968.png)](https://github.com/kombai/freewall)  | [![](img_readme/social_wall-87882.png)](https://github.com/kombai/freewall)  | [![](img_readme/social_wall-2780a.png)](https://github.com/kombai/freewall)  |  [![](img_readme/social_wall-4a303.png)](https://github.com/kombai/freewall) | ![](img_readme/social_wall-square.png) | ![](img_readme/social_wall-timeline.png) |
 --- | --- | --- | --- | --- | --- | ---
 Flexible Layout | Images show | Pinterest-like | Windows style | Fixed size |  Timeline | Another Layout?

Images from @Kombai plugin under the MIT license

### What do you want to highlight?
Examples of criteria or questions you should ask yourself or your client:
Some questions might need to improve this plugin !

 - Which number of posts to display (for all networks ? One network is preferred ?)
 - Do you need Hashtags filters ?
 - Show to your public one or many accounts (external: retweet, hashtags,...)
 - Sort by ? Date (usually newest), most liked/retweet/favorite posts,...
 - Which media to prioritize ? Text vs Pictures ? Video, GIF ?

## Installation

1. Copy th folder `social_wall`  into `_plugins`  within your Jekyll project.
2. Generate your social networks credentials
 - Facebook
    - Create and app: https://developers.facebook.com/docs/apps/register
 - Twitter
    - https://dev.twitter.com/oauth/overview
3. Create a `.env` file with your social networks credentials

  ```
  # Facebook credentials

  FACEBOOK_ACCESS_TOKEN=myaccestoken
  FACEBOOK_SECRET=mysecret

  # Twitter credentials

  TWITTER_CONSUMER_KEY=myconsumerkey
  TWITTER_CONSUMER_SECRET= myconsumersecret
  TWITTER_OAUTH_TOKEN=myoauthtoken
  TWITTER_OAUTH_TOKEN_SECRET=myoauthtokensecret
  ```
4. Install the following gem by adding them to your `_config.yml` and running `bundle install`

  ```yaml
  gem 'dotenv', :groups => [:development, :test]

  gem "koala", "~> 2.2"

  gem "twitter", "~> 6.0.0"
  ```
5. Configure a webhook subscription every social network used
 - Facebook
    - https://developers.facebook.com/docs/graph-api/webhooks
 - Twitter
    - doesn't have their own Webhook service but you can use : https://zapier.com/zapbook/twitter/webhook/, https://ifttt.com/ ...
6. Customize the html template by rewriting the ruby files inside the `social_networks` folder
7. **Enjoy!**

## How To Use
Add the following liquid tag in any of your layout or pages. Every social network is optional. Remove `??_username` to disable one.

```liquid
{% social_wall

  tw_username: lausanne2020,
  tw_count: 14,

  fb_username: lausanne2020,
  fb_count: 4,
%}
```

### Parameters

Name| Description|Default Value| Limitation | Example
----|----|----|----|----
tw_username| any twitter username but only one! |  | | katyperry
tw_count| exact number of tweets needed| 10 | [200](https://dev.twitter.com/rest/reference/get/statuses/user_timeline#parameters) | 36
tw_include_rts| retweets are fetched <sup>1</sup> | false | | true
fb_username| any facebook username but only one! | | | bbcnews
fb_count| exact number of posts needed| 10 | limited | 10

1. No special template at the moment

## Output example

```html
<div id='social_wall'>
  <div class='facebook_status link'>
    <p class="status">Lausanne2020 prend forme... Un point sur l'avancement des préparatifs, à (presque!) trois ans de la cérémonie d'ouverture!<a class="hashtag" href="https://www.facebook.com/hashtag/Lausanne2020">#Lausanne2020</a> <a class="hashtag" href="https://www.facebook.com/hashtag/thisiswhereitstarts">#thisiswhereitstarts</a> <a class="hashtag" href="https://www.facebook.com/hashtag/IloveYOG">#IloveYOG</a> <a class="hashtag" href="https://www.facebook.com/hashtag/24heures">#24heures</a></p>
    <blockquote cite="http://www.24heures.ch/sports/lausanne-2020-promouvoir-savoirfaire-formation-suisse/story/15546197">
      <p class="story_img"><a href="http://www.24heures.ch/sports/lausanne-2020-promouvoir-savoirfaire-formation-suisse/story/15546197"><img src="https://external.xx.fbcdn.net/safe_image.php?d=AQDRiWmt_TeB8kt1&w=130&h=130&url=http%3A%2F%2Fmcdn.newsnetz.ch%2Fstory%2F1%2F5%2F5%2F15546197%2Fpictures%2F1%2Fteaser_t_1024.jpg%3F1&cfs=1&sx=0&sy=0&sw=682&sh=682&_nc_hash=AQDWLuD6ChUhJcaG"></a></p>
      <h2>Lausanne 2020 va promouvoir le savoir-faire et la formation suisse</h2>
      <p class="desc">A trois ans de la grande fête du sport des 15-18 ans, les universités, les services cantonaux de l’éducation, les hautes écoles et la filière de l’apprentissage s’activent en coulisses.</p>
      <cite>24heures.ch</cite>
    </blockquote>
    <p class="info">
      <span class="icon">f</span>
      <span class="user"><a href="https://www.facebook.com/Lausanne2020">Lausanne2020</a></span>
      <time pubdate datetime="2016-12-27T19:32:12-08:00">2016-12-27T19:32:12-08:00</time>
      <a class="share icon" href="http://www.facebook.com/share.php?v=4&amp;src=bm&amp;u=http%3A%2F%2Fwww.24heures.ch%2Fsports%2Flausanne-2020-promouvoir-savoirfaire-formation-suisse%2Fstory%2F15546197"></a>
    </p>
  </div>
  <div class='twitter_status'>
    <img src="http://pbs.twimg.com/media/C0XiRYMXAAAOIf4.jpg:small" />
    <p class="status" id="812305374862835712">Official! Our Monobob,Skeleton &amp;Luge events will take place on the Olympic site of St-Moritz! <a href="https://t.co/lVMVg9Ca6W">https://t.co/lVMVg9Ca6W</a> <a class="mention" href="http://twitter.com/IBSFsliding">@IBSFsliding</a> <a class="mention" href="http://twitter.com/FIL_Luge">@FIL_Luge</a> </p>
    <p class="info">
      <span class="icon">t</span>
      <span class="user"><a href="http://twitter.com/lausanne2020">Lausanne 2020</a></span>
      <time pubdate datetime="2016-12-23T14:34:27-08:00">2016-12-23T14:34:27-08:00</time>
      <a href="https://twitter.com/intent/favorite?tweet_id=812305374862835712" class="favorite icon">R</a>
      <a href="https://twitter.com/intent/retweet?tweet_id=812305374862835712" class="retweet icon">J</a>
      <a href="https://twitter.com/intent/tweet?in_reply_to=812305374862835712" class="tweet icon">h</a>
    </p>
  </div>
</div>
```

## Futures Features
- [ ] Stripping multilingual duplicate posts
   - https://github.com/simplificator/babel
   - https://github.com/feedbackmine/language_detector
   - https://github.com/peterc/whatlanguage
   - https://github.com/vhyza/language_detection
   - https://github.com/detectlanguage/detectlanguage-ruby
- [ ] Twitter Video/Gif support
- [ ] Option to include hashtags posts for both Facebook and Twitter
- [ ] Support for others social networks
  - Instagram
  - Linkedin
  - Google+
  - VK
