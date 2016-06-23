class Tmux
  class << self
    def sessions
      `tmux ls`.lines.select{|l| l[/^[^:]+:\s+\d/i] }.map{|l| l[/^([^:]+)(?=:\s+\d+)/i] }
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
