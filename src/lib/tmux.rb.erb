class Tmux
  class << self
    def sessions
      `tmux ls`.lines.select{|l| l[/^[^:]+:\s+\d/i] }.map{|l| l[/^([^:]+)(?=:\s+\d+)/i] }
    end

    def session_exists?(name)
      sessions.include?(name)
    end

    def attach_to_session(name)
      exec("tmux a -t #{name}")
    end

    def new_session(name, path=Dir.pwd, *args)
      exec("tmux new -s #{name} -c #{path} " + args.join(' '))
    end
  end
end


# vim: ft=ruby
