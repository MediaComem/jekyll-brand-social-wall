module SharedMethods

  # Photo

  def photo_format(width, height)
    return "square" if width == height
    return "landscape" if width > height
    return "portrait" if height > width
  end

  # Video

  def is_facebook_video?(url)
    url =~ /^https:\/\/(video.xx.fbcdn.net|scontent.xx.fbcdn.net)/i
  end

  def is_youtube_video?(url)
    url =~ /http(?:s?):\/\/(?:www\.)?youtu(?:be\.com\/watch\?v=|\.be\/)([\w\-\_]*)(&(amp;)?‌​[\w\?‌​=]*)?/i
  end

  def is_vimeo_video?(url)
    url =~ /https?:\/\/.*vimeo\.com\/.*\d+/
  end

  def is_dailymotion_video?(url)
    url =~ /https?:\/\/.*dailymotion\.com\/.*\d+/
  end

  def get_video_provider(url)
    url = get_deep_link(url)

    return "facebook" if is_facebook_video?(url)
    return "youtube" if is_youtube_video?(url)
    return "vimeo" if is_vimeo_video?(url)
    return "dailymotion" if is_dailymotion_video?(url)

    return ""
  end

  def parse_video(url)
    # Youtube to Embed link
    url = url.gsub(/http(?:s?):\/\/(?:www\.)?youtu(?:be\.com\/watch\?v=|\.be\/)([\w\-\_]*)(&(amp;)?‌​[\w\?‌​=]*)?/i, 'https://www.youtube.com/embed/\1?autoplay=0&rel=0&amp;showinfo=0')
    # Youtube Remove Autoplay
    url = url.gsub('autoplay=1', 'autoplay=0&rel=0&amp;showinfo=0')
    return url
  end

  # File

  def path_exist?(path)
    File.exist? File.expand_path path
  end

  def create_path(path)
    FileUtils::mkdir_p path
  end

  # URLs

  def url_exist?(url)
    if(URI.parse(url).respond_to?(:request_uri)) # Prevent lot of wrong urls
      r = Net::HTTP.get_response(URI.parse(url))
      if [301, 302].include?(r.code)
        url_exist?(r.header['location']) # Go after any redirect and make sure you can access the redirected URL
      else
        ! %W(4 5).include?(r.code[0]) # Not from 4xx or 5xx families
      end
    else
      false
    end
  rescue Errno::ENOENT
    false #false if can't find the server
  end

  # Against shortener URL services...
  def get_deep_link(url)
    r = Net::HTTP.get_response(URI.parse(url))

    if [301, 302].include?(r.code.to_i)
      get_deep_link(r.header['location']) # Go after any redirect and make sure you can access the redirected URL
    else
      return url
    end
  end

end
