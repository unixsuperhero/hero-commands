class Value
  attr_reader :default
  def initialize(hash, default: nil)
    merge hash
    @default = default
  end

  def merge(hash)
    singleton.send(:attr_accessor, *hash.keys.map(&:to_sym))
    hash.each{|k,v| instance_variable_set("@#{k}", v) }
  end
  alias_method :update, :merge

  def method_missing(name, *args)
    default.dup
  end

  private def singleton
    instance_eval('class << self; self; end')
  end
end
