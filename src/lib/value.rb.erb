class Value
  def initialize(hash)
    merge hash
  end

  def merge(hash)
    singleton.send(:attr_accessor, *hash.keys.map(&:to_sym))
    hash.each{|k,v| instance_variable_set("@#{k}", v) }
  end
  alias_method :update, :merge

  private def singleton
    instance_eval('class << self; self; end')
  end
end
