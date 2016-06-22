module LetHelpers
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def let(name, &block)
      define_singleton_method(name, &block)
    end
  end
end
