
class Project
  class << self
    def config
      Config.new(yaml_file, 'projects').tap{|configuration|
        configuration.after_read do |this|
          this.data.map{|k,v|
            expanded_path = File.expand_path(v)
            dug = this.instance_variable_get(:@data)
            dug = dug.dig(*this.data_path)
            dug.merge!(k => expanded_path)
          }
        end

        configuration.before_save do |this|
          this.data.map{|k,v|
            relative_path = v.sub(%r{^(/(?:Users|home)/[^/]+)(/?)}, '~\2/').sub(%r{//+}, ?/)
            dug = this.instance_variable_get(:@data)
            dug = dug.dig(*this.data_path)
            dug.merge!(k => relative_path)
          }
        end
        configuration.read!
      }
    end

    def project_matcher
      SubcommandMatcher.from(config.data)
    end

    def yaml_file
      File.join(Dir.home, 'projects.yml')
    end

    def projects
      config.data.keys
    end

    def dirs
      config.data.values
    end

    def tmux_session_for_project(project_name)
      name = project_matcher.match_name(project_name)
      path = project_matcher.match(project_name)

      error_exit('No project found matching "%s"...' % project_name) unless name

      puts
      puts format('Project Name: %s', name)
      puts format('Project Path: %s', path)
      puts

      if Tmux.session_exists?(name)
        Tmux.attach_to_session(name)
      else
        Tmux.new_session(name, path)
      end
    end
  end
end

