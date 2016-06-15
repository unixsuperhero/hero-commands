class Heroku
  class << self
    def qa_remote_name(project, branch)
      format('%s-%s', project, branch.gsub(/\W+/, ?-))
    end

    def apps
      app_remotes.values.uniq
    end

    def remotes
      app_remotes.keys
    end

    def app_remotes
      `git remote -v`.lines.map(&:chomp).select{|l|
        l[/heroku/i]
      }.inject({}){|h,remote|
          rem = remote[/^\S+/]
          app = remote[/(?<=[\/:])[^\/]+(?=[.]git)/i]
          h.merge(rem => app)
      }
    end
  end
end


# vim: ft=ruby
