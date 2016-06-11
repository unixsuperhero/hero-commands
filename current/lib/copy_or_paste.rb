

class CmdPipe
  class << self
    def run(*args)
      new(*args).tap{|runner| runner.run }
    end

    def output(*args)
      new(*args).output
    end

    def print(*args)
      new(*args).print
    end
  end

  attr_accessor :chain, :options
  attr_accessor :reader, :writer
  def initialize(*args)
    @options = args.last.is_a?(Hash) ? args.pop : {}
    @chain = CommandChain.from_list(args.flatten) #.map{|cmd| Command.new(cmd) }
    @reader, @writer = IO.pipe
    # @pipes = Pipe.from_commands(@commands)
  end

  def run
    last_command = chain.last_command
    last_command.writer = writer

    chain.run

    reader.read.tap{|stdoutput|
      reader.close
      writer.close unless writer.closed?
    }
  end

  def output
    @output ||= run
  end

  def print
    puts output
  end

  class CommandChain
    class << self
      attr_accessor :first_command, :last_command

      def set_first_command(cmd)
        @first_command = cmd
      end

      def set_last_command(cmd)
        @last_command = cmd
      end

      def from_list(cmds)
        cmds.reverse.inject(nil){|piping_to,shell_cmd|
          new(shell_cmd, piping_to).tap do |precmd|
            if piping_to
              piping_to.precmd = precmd
            else
              set_last_command(precmd)
            end
          end
        }.tap{|first_command|
          set_first_command(first_command)
          cmd = first_command
          while cmd.subcmd
            r,w = IO.pipe

                   cmd.writer = w
            cmd.subcmd.reader = r

            cmd = cmd.subcmd
          end
        }
      end
    end

    attr_accessor :shell_cmd, :subcmd, :precmd
    attr_accessor :reader, :writer
    def initialize(shell_cmd, to_cmd=nil, from_cmd=nil)
      @shell_cmd, @subcmd, @precmd = shell_cmd, to_cmd, from_cmd
    end

    def first
      first_command
    end

    def last
      last_command
    end

    def last_command
      @last_command ||= subcmd ? subcmd.last_command : self
    end

    def first_command
      @first_command ||= precmd ? precmd.first_command : self
    end

    def to_a
      @to_array ||= [first_command].tap do |list|
        while list.last.subcmd
          list.push list.last.subcmd
        end
      end
    end

    def position
      to_a.index(self) + 1
    end

    def exec
      opts = {}
      opts.merge!(in: reader) if reader
      opts.merge!(out: writer) if writer
      system(shell_cmd, opts)
    end

    def run
      exec
      reader.close if reader
      writer.close if writer
      subcmd.run if subcmd
    end
  end
end



class CopyOrPaste
  class << self
    def copy(text, with_newline=false)
      CmdPipe.run("printf '%s'" % text, 'pbcopy')
      # cmd = with_newline ? 'echo' : 'printf'
      # `#{cmd} '#{text.chomp}' | pbcopy`
      show_copied_text
    end

    def show_copied_text
      system(%{printf 'The text copied was: "%s"' "$(pbpaste)"})
    end

    def paste(text=nil)
      system('pbpaste')
    end
  end
end

