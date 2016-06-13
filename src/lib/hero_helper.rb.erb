class HeroHelper
  class << self
    def edit_in_editor(*args)
      exec cmd_from(args.unshift(editor))
    end

    def cmd_from(*args)
      args.flatten.shelljoin
    end

    def editor
      ENV.fetch('EDITOR', 'vim')
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
