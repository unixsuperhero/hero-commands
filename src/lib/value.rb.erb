class Value
  attr_reader :to_h

  def initialize(hash)
    @to_h = hash
    hash.each{|k,v|
      define_singleton_method(k){ v }
    }
  end

  def merge(hash)
    @to_h.merge!(hash)
    hash.each{|k,v|
      define_singleton_method(k){ v }
    }
  end
  alias_method :update, :merge

  def set(k, v)
    merge(k => v)
  end

  def get(k)
    to_h[k]
  end

  def has?(k)
    respond_to?(k)
  end
end
