class Helpers
  class << self
    def register_helper(name, klass)
      define_singleton_method(name){ klass }
    end
  end
end


class BrewHelper
end

class Helpers
  register_helper :brew, BrewHelper
end

class BrewHelper
  class << self
    def brewfile
      File.join(Dir.home, 'Brewfile')
    end

    def list
      IO.readlines(brewfile).map(&:chomp).reject{|keg|
        keg[/^\s*#|^\s*$/]
      }
    end

    def installed
      `brew list`.lines.map(&:strip).join(' ').split(/\s+/)
    end

    def pending
      list - installed
    end
  end

  class Installer
    class << self
      def run(keg)
        new(keg).tap(&:run)
      end
      alias_method :keg, :run
    end

    attr_reader :keg
    def initialize(keg)
      @keg = keg
    end

  end
end

# vim: ft=ruby
