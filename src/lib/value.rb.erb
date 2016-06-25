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
    self.tap{|this|
      @to_h.delete(k)
      instance_eval(format("undef %s", k)) if respond_to?(k)
    }
  end
  alias_method :unset, :delete

  def set(k, v)
    merge(k => v)
  end

  def get(k)
    to_h[k]
  end

  def has?(k)
    respond_to?(k)
  end

  def method_missing(name, args)
    ap(inside: :method_missing, name: name, args: args)
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
