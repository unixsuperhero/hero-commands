class Helpers
  class << self
    def register_helper(name, klass)
      define_singleton_method(name){ klass }
    end
  end
end
