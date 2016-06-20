class ListFilter
  class << self
    def run(list, *patterns, accessor: nil, **opts, &block)
      self.or(list, *patterns, accessor: nil, **opts, &block)
    end

    def and(list, *patterns, accessor: nil, **opts, &block)
      new(list, *patterns, accessor: nil, **opts, &block).and
    end

    def or(list, *patterns, accessor: nil, **opts, &block)
      new(list, *patterns, accessor: nil, **opts, &block).or
    end
  end

  attr_reader :original, :list, :patterns
  attr_reader :accessor, :opts
  def initialize(list, *patterns, accessor: nil, **opts, &block)
    @original, @list, @patterns = list.dup, list, patterns
    @accessor = accessor
    @accessor ||= block if block_given?
    @opts = opts
  end

  def apply_pattern(list, pattern)
    list.select{|item|
      item = accessor.call(item) if accessor
      item[pattern]
    }
  end

  def and
    @and_result ||= patterns.inject(list){|items,pattern|
      apply_pattern(items, pattern)
    }
  end
  alias_method :use_and, :and
  alias_method :with_and, :and

  def or
    @or_result ||= patterns.flat_map{|pattern|
      apply_pattern(list, pattern)
    }.uniq
  end
  alias_method :use_or, :or
  alias_method :with_or, :or
end


# vim: ft=ruby
