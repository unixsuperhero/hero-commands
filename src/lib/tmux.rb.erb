class Tmux
  class << self
    def sessions(*patterns)
      list = HeroHelper.output_lines_from(*'tmux ls'.shellsplit).select{|l|
        l[/^\S[^:]*:/]
      }.map{|l|
        l.sub(/:.*/, '')
      }.compact

      return list if patterns.empty?

      ListFilter.run(list, *patterns)
    end

    def commands(*patterns)
      hash = HeroHelper.output_lines_from(*'tmux list-commands'.shellsplit).map{|l|
        [ l[/\S+/], l ]
      }.to_h

      return hash if patterns.empty?

      list = ListFilter.run(hash.keys, *patterns)
      list.map{|key| [ key, hash[key] ] }.to_h
    end

    def keys(*patterns)
      list = HeroHelper.output_lines_from(*'tmux list-keys'.shellsplit).map{|l|
        l.scan(/^(bind-key)\s*(-r)?\s*(-T\s\s*\S\S*)\s*(\S+)\s*(\S.*)$/i).flatten #(?:\s*-+\w+)+\s*(?=\S)(?!-))(\S+\s+\S+)(?:\s*(\S.*))?$/)
      }

      return list if patterns.empty?

      matches = ListFilter.run(list, *patterns){|item|
        item[3]
      }

      matches = ListFilter.run(list, *patterns){|item|
        item[3..-1].join(' ')
      } if matches.empty?

      return matches if matches.empty?

      HeroHelper.matrix_to_table(matches)
    end

    def windows(*patterns)
      list = HeroHelper.output_lines_from(*'tmux list-windows'.shellsplit)

      return list if patterns.empty?

      ListFilter.run(list, *patterns)
    end

    def panes(*patterns)
      list = HeroHelper.output_lines_from(*'tmux list-panes'.shellsplit)

      return list if patterns.empty?

      ListFilter.run(list, *patterns)
    end

    def buffers(*patterns)
      list = HeroHelper.output_lines_from(*'tmux list-buffers'.shellsplit)

      return list if patterns.empty?

      ListFilter.run(list, *patterns)
    end

    def clients(*patterns)
      list = HeroHelper.output_lines_from(*'tmux list-clients'.shellsplit)

      return list if patterns.empty?

      ListFilter.run(list, *patterns)
    end

    def session_exists?(name)
      sessions.include?(name)
    end

    def switch_to_session(name)
      exec("tmux switchc -t #{name}")
    end

    def attach_to_session(name)
      exec("tmux a -t #{name}")
    end

    def new_session(name, path=Dir.pwd, *args)
      exec("tmux new -s #{name} -c #{path} " + args.join(' '))
    end

    def new_detached_session(name, path=Dir.pwd)
      system("tmux new -d -s #{name.shellescape} -c #{path.shellescape}")
    end

    def in_tmux?
      ENV.has_key?('TMUX')
    end

    def join_new_session(name, path=Dir.pwd)
      if in_tmux?
        new_detached_session(name, path)
        switch_to_session(name)
      else
        new_session(name, path)
      end
    end

    def join_existing_session(name, path=Dir.pwd)
      if in_tmux?
        switch_to_session(name)
      else
        attach_to_session(name)
      end
    end

    def force_session(name, path=Dir.pwd, *args)
      if session_exists?(name)
        join_existing_session(name)
      else
        join_new_session(name, path)
      end
    end
  end
end


# vim: ft=ruby
