class HeroHelper
  class << self
    def matrix_to_table(matrix)
      col_sizes = matrix.inject([]){|sizes,cols|
        cols.map.with_index{|col,i|
          cur_len = sizes[i] || 0
          new_len = col.to_s.length
          new_len > cur_len ? new_len : cur_len
        }
      }

      matrix.map{|cols|
        col_sizes.map.with_index{|csize,i|
          cols[i].to_s.ljust(csize+1).rjust(csize+2)
        }.join(?|)
      }
    end

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
    alias_method :cmd_for, :cmd_from

    def system_env_vars
      { 'MANPAGER' => 'cat' }
    end

    def system_from(*args)
      system system_env_vars, cmd_from(*args)
    end
    alias_method :system_for, :system_from

    def exec_from(*args)
      exec cmd_from(*args)
    end
    alias_method :exec_for, :exec_from

    def plainify(str_or_lines)
      if str_or_lines.is_a?(Array)
        str_or_lines.map{|l| plainify(l) }
      else
        str_or_lines.gsub(/\e\S(\d+;)*\d*[mG]|.\b+/, '')
      end
    end

    def plain_from(*args)
      (output_from(*args) || '').gsub(/\e\S(\d+;)*\d*[mG]|.\b/, '')
    end
    alias_method :plain_for, :plain_from

    def plain_lines_from(*args)
      plain_from(*args).lines.map(&:chomp)
    end
    alias_method :plain_lines_for, :plain_lines_from

    def output_from(*args)
      r,w = IO.pipe
      system system_env_vars, cmd_from(*args), out: w
      w.close
      r.read.tap{|output| r.close }
    end
    alias_method :output_for, :output_from

    def output_lines_from(*args)
      output_from(*args).lines.map(&:chomp)
    end
    alias_method :output_lines_for, :output_lines_from

    class PipeCommand
      attr_accessor :cmd, :reader, :writer
      def initialize(cmd)
        @cmd = cmd
      end

      def run
        system(HeroHelper.system_env_vars, cmd,
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
      system system_env_vars, cmd_from('mkdir', '-pv', dir_only)
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
