class DotHash
  class << self
    def for(file)
      new(file)
    end
  end

  attr_accessor :official_data
  attr_accessor :mapped_data
  def initialize(h)
    @official_data = h.clone
    @mapped_data = h.clone
  end

  def [](key)
    config_data[key]
  end

  def []=(key, val)
    config_data[key] = val
  end

  def save
    IO.write(filename, YAML.dump(config_data))
  end

  def file_exists?
    File.exist?(filename)
  end

  def write_empty_config_if_file_is_missing
    return if file_exists?
    IO.write filename, YAML.dump({})
  end

  def method_missing(key, *args)
    base,operator = key.to_s.split(/(?<=\w)(?=\W*$)/i).push('')
    matchers = 0.upto(operator.length).flat_map{|len|
      m = base + operator.slice(0,len)
      [m, m.to_sym]
    }

    matching_key = config_data.keys.find{|k| matchers.include?(k) }

    # if it's a getter
    if args.count == 0
      config_data[matching_key]

    # if it's a setter and the matched and existing key
    elsif matching_key
      config_data.merge! matching_key => args.first

    # if it's a setter and it's a new key
    else
      config_data[base] = args.first
    end
  end
end
