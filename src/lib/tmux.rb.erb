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

      matches.tap{|matrix|
        puts HeroHelper.matrix_to_table(matrix)
      }
    end

    # "list-sessions" => "list-sessions (ls) [-F format]",
    # "list-commands" => "list-commands (lscm) ",
    #     "list-keys" => "list-keys (lsk) [-t mode-table] [-T key-table]",

    #  "list-buffers" => "list-buffers (lsb) [-F format]",
    #  "list-clients" => "list-clients (lsc) [-F format] [-t target-session]",
    #    "list-panes" => "list-panes (lsp) [-as] [-F format] [-t target-window]",
    #  "list-windows" => "list-windows (lsw) [-a] [-F format] [-t target-session]"

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

    def new_detached_session(name, path=Dir.pwd)
      system("tmux new -d -s #{name.shellescape} -c #{path.shellescape}")
    end

    def force_session(name, path=Dir.pwd, *args)
      if session_exists?(name)
        if ENV.has_key?('TMUX')
          switch_session(name)
        else
          attach_to_session(name)
        end
      else
        if ENV.has_key?('TMUX')
          puts 'new detached session: %s => %s' % [name,path]
          new_detached_session(name, path)
          puts 'switching to session: %s' % [name]
          switch_session(name)
        else
          new_session(name, path)
        end
      end
    end
  end
end


# vim: ft=ruby
