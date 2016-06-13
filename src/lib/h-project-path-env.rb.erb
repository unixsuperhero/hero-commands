class HProjectPathEnv
  class << self
    def env
      ENV['PATH']
    end

    def split
      env.split(/:+/)
    end

    def list
      split.inject([]) do |arr,path|
        next arr unless File.exist?(path)
        arr.include?(path) ? arr : arr.push(path)
      end
    end

    def absolute_paths
      split.inject([]) do |list,path|
        abspath = File.absolute_path(path)
        next list unless File.exist?(abspath)
        list.include?(abspath) ? list : list.push(abspath)
      end
    end

    def all_glob(pattern='')
      format '{%s}/%s', list.join(?,), pattern
    end

    def find(exact_name)
      Dir[all_glob(exact_name)]
    end

    def search(name)
      Dir[all_glob('*%s*' % name)]
    end

    def fuzzy_search(pattern)
      Dir[all_glob('*%s*' % name.chars.join(?*))]
    end
  end
end


# vim: ft=ruby
