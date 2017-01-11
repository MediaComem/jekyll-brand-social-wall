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

  def self.parse_liquid_params(params)
      attributes = {}
      params.scan(::Liquid::TagAttributes) do |key, value|
        attributes[key] = value
      end
      return attributes
  end

  def self.rename_symbole(hash, old_symbole, new_symbole)
    new_hash = []
    for key in hash
      key[new_symbole] = key.delete old_symbole
      new_hash << (key)
    end
    return new_hash
  end

end

# A collection of methods which extend ruby classes

class String

  def truncate(max)
      length > max ? "#{self[0...max]}..." : self
  end

end
