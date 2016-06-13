class HeroHelper
  class << self
    def edit_in_editor(*args)
      exec cmd_from(args.unshift(editor))
    end

    def cmd_from(*args)
      args.flatten.shelljoin
    end

    def mkdirs_for_file(file)
      return false if File.exist?(file)
      mkdirs File.dirname(file)
    end

    def mkdirs(dir_only)
      return false if File.exist?(dir_only)
      system cmd_from('mkdir', '-pv', dir_only)
    end

    def editor
      ENV.fetch('EDITOR', 'vim')
    end

    def everything_in_dir(dir)
      Dir[File.join(dir, '**/*')]
    end

    def files_in_dir(dir)
      everything_in_dir(dir).select(&File.method(:file?))
    end

    def folders_in_dir(dir)
      everything_in_dir(dir).select(&File.method(:directory?))
    end

    def run_inside_dir(dir, &block)
      return false unless block_given?
      pwd = Dir.pwd.tap{
        Dir.chdir(dir)
      }

      block.call.tap{
        Dir.chdir(pwd)
      }
    end
  end
end


# vim: ft=ruby
