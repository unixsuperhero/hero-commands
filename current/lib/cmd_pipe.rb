
class CmdPipe
  attr_accessor :commands, :pipes, :options
  attr_accessor :reader, :writer
  def initialize(*args)
    @options = args.last.is_a?(Hash) ? args.pop : {}
    @commands = CommandChain.from_list(args.flatten) #.map{|cmd| Command.new(cmd) }
    @reader, @writer = IO.pipe
    # @pipes = Pipe.from_commands(@commands)
  end

  def run
    last_command = commands.last_command
    last_command.writer = writer

    commands.run

    reader.read.tap{|r|
      r.close
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
          r,w = nil,nil
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

    def last_command
      subcmd ? subcmd.last_command : self
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
      if subcmd
        subcmd.run
      end
    end
  end
end

