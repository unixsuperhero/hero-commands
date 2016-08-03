class Helpers
  class << self
    def register_helper(name, klass)
      define_singleton_method(name){ klass }
    end
  end
end


class BrewHelper
end

class BrewInstaller
end

class Helpers
  register_helper :brew, BrewHelper
  register_helper :brew_installer, BrewInstaller
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

    def installed?(keg)
      installed.include?(keg)
    end

    def pending
      list - installed
    end

    def install(keg)
      Helpers.brew_installer.run(keg)
    end
  end
end

class BrewInstaller
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

  def run
    if installed?
      @reason = :installed
      return @success = false
    end

    unless @success = system('brew', 'install', keg)
      @reason = :unknown
    end
  end

  def installed?
    Helpers.brew.installed? keg
  end

  def successful?
    @success == true
  end

  def reason
    @reason
  end
end

# vim: ft=ruby
