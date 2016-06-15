class HeroHelper
  class << self
    def string_to_underscores(str)
      str.split(/[\s_-]+/).flat_map{|part|
        part.split(/(?<=[a-z])(?=[A-Z])/)
      }.flat_map{|part|
        part.split(/(?<=[A-Z])(?=[A-Z][a-z])/)
      }.map(&:downcase).join(?_)
    end

    def string_to_classname(str)
      string = str.to_s
			string = string.sub(/^[a-z\d]*/) { |match| match.capitalize }
      string.gsub!(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{$2.capitalize}" }
      string.gsub!('/'.freeze, '::'.freeze)
      string
    end

    def edit_in_editor(*args)
      exec cmd_from(args.unshift(editor))
    end

    def cmd_from(*args)
      parts = args.flatten

      if parts.first[/\w\s+--?\w/i]
        cmd_with_options = parts.shift
        start_cmd = Shellwords.split(cmd_with_options)
        parts = start_cmd + parts
      end

      parts.shelljoin
    end

    def system_from(*args)
      system cmd_from(*args)
    end

    def exec_from(*args)
      exec cmd_from(*args)
    end

    def output_from(*args)
      r,w = IO.pipe
      system cmd_from(*args, out: w)
      w.close
      r.read.tap{|output| r.close }
    end

    class PipeCommand
      attr_accessor :cmd, :reader, :writer
      def initialize(cmd)
        @cmd = cmd
      end

      def run
        system(cmd,
          {}.tap{|opts|
            opts.merge!(in: reader) if reader
            opts.merge!(out: writer) if writer
          }
        ).tap{
          reader.close if reader
          writer.close if writer
        }
      end
    end

    def pipe_cmds(*cmds)
      pcmds = cmds.flatten.map(&PipeCommand.method(:new))
      return '' if cmds.empty?
      pcmds.each_cons(2).to_a.each{|b,a|
        a.reader, b.writer = IO.pipe
      }
      final_reader, pcmds.last.writer = IO.pipe
      pcmds.each(&:run)
      final_reader.read{ final_reader.close }
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
