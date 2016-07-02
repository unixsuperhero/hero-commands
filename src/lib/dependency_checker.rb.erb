class DependencyChecker
  class << self
    def brew(keg_name, display_name=nil)
      matches = PathEnv.find(keg_name) || []
      if matches.count == 0
        install_missing_brew_dependency(keg_name, display_name)
      end
      return (PathEnv.find(keg_name) || []).count > 0
    end

    def install_missing_brew_dependency(keg_name, display_name=nil)
      if (PathEnv.find('brew') || []).count == 0
        puts <<-MESSAGE
  Missing Dependency: #{display_name || keg_name}

  Homebrew is required to install this missing dependency.

  Please visit http://brew.sh for instructions.
        MESSAGE
        return false
      else
        printf <<-MESSAGE
  Missing Dependency: #{display_name || keg_name}

  Would you like to install it (default: y)? [yn]
        MESSAGE

        STDOUT.flush
        answer = STDIN.gets

        if answer == ?y
          install_keg(keg_name)
        end
      end
    end

    def install_keg(keg_name)
      system('brew', 'install', keg_name)
    end
  end
end


# vim: ft=ruby
