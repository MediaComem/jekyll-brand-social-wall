# A collection of methods which extend ruby classes

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


class DateTime
  # Extends class DateTime with Rails method: http://apidock.com/rails/DateTime/change
  def change(options)
      ::DateTime.civil(
        options.fetch(:year, year),
        options.fetch(:month, month),
        options.fetch(:day, day),
        options.fetch(:hour, hour),
        options.fetch(:min, options[:hour] ? 0 : min),
        options.fetch(:sec, (options[:hour] || options[:min]) ? 0 : sec + sec_fraction),
        options.fetch(:offset, offset),
        options.fetch(:start, start)
      )
  end
end
