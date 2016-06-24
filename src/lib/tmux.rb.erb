class Tmux
  class << self
    def sessions(*patterns)
      list = HeroHelper.output_lines_from(*'tmux ls'.shellsplit).map{|l|
        next unless l[/^\S[^:]*:/]
        l.sub(/:.*/, '')
      }.compact
      patterns.any? ? ListFilter.run(list, *patterns) : list
      # `tmux ls`.lines.select{|l| l[/^[^:]+:\s+\d/i] }.map{|l| l[/^([^:]+)(?=:\s+\d+)/i] }
    end

    def commands(*patterns)
      hash = HeroHelper.output_lines_from(*'tmux list-commands'.shellsplit).map{|l|
        [ l[/\S+/], l ]
      }.to_h

      if patterns.any?
        list = ListFilter.run(hash.keys, *patterns)
        list.map{|key| [ key, hash[key] ] }.to_h
        # hash.select{|k,v| list.include?(k) }
      else
        hash
      end
    end

    def keys(*patterns)
      hash = HeroHelper.output_lines_from(*'tmux list-keys'.shellsplit).flat_map{|l|
        l.scan(/^(bind-key)\s*(-r)?\s*(-T\s\s*\S\S*)\s*(\S+)\s*(\S.*)$/i) #(?:\s*-+\w+)+\s*(?=\S)(?!-))(\S+\s+\S+)(?:\s*(\S.*))?$/)
      }

      patterns.any? ? ListFilter.run(hash, *patterns){|item|
        '%s %s' % [item[3], item[4]]
      } : hash
    end

    def session_exists?(name)
      sessions.include?(name)
    end

    def switch_session(name)
      exec("tmux switchc -t #{name}")
    end

    def attach_to_session(name)
      exec("tmux a -t #{name}")
    end

    def new_session(name, path=Dir.pwd, *args)
      exec("tmux new -s #{name} -c #{path} " + args.join(' '))
    end

    def force_session(name, path=Dir.pwd, *args)
      if session_exists?(name)
        if ENV.has_key?('TMUX')
          switch_session(name)
        else
          attach_to_session(name)
        end
      else
        new_session(name, path)
      end
    end
  end
end


# vim: ft=ruby
