class Tmux
  class << self
    def session_exists?(name)
      `tmux ls`.lines.any?{|l| l[/^#{name}:/] }
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
