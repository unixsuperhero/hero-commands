
class Value
  attr_reader :to_h

  def initialize(hash)
    @to_h = hash
    hash.each{|k,v|
      define_singleton_method(k){ v }
    }
  end

  def merge(hash)
    self.tap{|this|
      @to_h.merge!(hash)
      hash.each{|k,v|
        define_singleton_method(k){ v }
      }
    }
  end
  alias_method :update, :merge

  def delete(k)
    @to_h.delete(k)
    undef k if respond_to?(k)
  end

  def set(k, v)
    merge(k => v)
  end

  def get(k)
    to_h[k]
  end

  def has?(k)
    respond_to?(k)
  end

  def [](key)
    get(key)
  end

  def []=(key,val)
    val.tap{
      @to_h.merge! key => val
      define_singleton_method(key){ val }
    }
  end
end


class NameMatcher
  attr_accessor :name_map, :names

  def initialize(hash)
    @name_map = hash
    @names = hash.keys
  end

  def grouped_by_values
    @grouped_by_values ||= name_map.map{|k,v|
      [v, names.select{|oname| name_map[oname] == v }]
    }
  end

  def name_groups
    @name_groups ||= grouped_by_values.inject({}){|h,(k,grouped_names)|
      grouped_names.map{|name| h.merge!(name => grouped_names) }
      h
    }
  end

  def partials
    @partials ||= names.map{|name| [name, partials_for(name)] }.to_h
  end

  def partials_for(str)
    str.chars.inject([]) do |arr,c|
      arr.push((arr.last || '') + c)
    end
  end

  def uniq_partials
    @uniq_partials ||= names.map{|name|
      other_partials = (names - name_groups[name]).flat_map{|oname| partials[oname] }.sort.uniq
      other_partials -= [name]
      [name, partials[name] - other_partials]
    }.to_h
  end

  def shortest_partials
    @shortest_partials ||= names.map{|name|
      [name, uniq_partials[name].min_by(&:length)]
    }.to_h
  end

  def usages
    @usages ||= names.map{|name|
      shortest = shortest_partials[name]
      next [name,name] if shortest == name
      [name, format('%s[%s]', name[0,shortest.length], name[(shortest.length)..-1])]
    }.to_h
  end

  def info
    @info ||= names.map{|name|
      [
        name,
        Value.new(
          name: name,
          data: name_map[name],
          similar_names: name_groups[name],
          partials: partials[name],
          matching_partials: uniq_partials[name],
          shortest_partial: shortest_partials[name],
          syntax: usages[name],
          usage: usages[name],
        )
      ]
    }.to_h
  end

  def match(str)
    found = info.find{|name,info| info.matching_partials.include?(str) }
    found.last if found
  end

  def match_name(str)
    found = info.find{|name,info| info.matching_partials.include?(str) }
    found.first if found
  end

  def match_data(str)
    found = info.find{|name,info| info.matching_partials.include?(str) }
    found.last.data if found
  end
end
