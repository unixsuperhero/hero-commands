

class CmdPipe
  class << self
    def run(*args)
      new(*args).tap{|cmd_pipe| cmd_pipe.run }
    end

    def output(*args)
      new(*args).output
    end

    def print(*args)
      new(*args).print
    end
  end

  attr_accessor :chain, :options
  # attr_accessor :reader, :writer
  def initialize(*args)
    @options = args.last.is_a?(Hash) ? args.pop : {}
    @chain = CommandChain.new(args.flatten) #.map{|cmd| Command.new(cmd) }
    # @reader, @writer = IO.pipe
    # @pipes = Pipe.from_commands(@commands)
  end

  def shell_commands
    chain.shell_commands
  end

  def runners
    chain.runners
  end

  def run
    chain.run
  end

  def output
    chain.output
  end

  def print
    chain.print
  end

  class CommandChain
    attr_accessor :shell_commands, :runners
    attr_accessor :reader, :writer
    def initialize(cmds)
      @shell_commands = cmds
      @runners = cmds.map(&Runner.method(:new))
      @reader, @writer = IO.pipe

      assign_chain_and_position_to_runners
      assign_io_for_each_pipe
    end

    def assign_chain_and_position_to_runners
      runners.each_with_index{|runner,idx|
        runner.chain = self
        runner.position = idx
      }
    end

    def assign_io_for_each_pipe
      runners.each_cons(2){|write_to,read_from|
        r,w = IO.pipe
        write_to.writer = w
        read_from.reader = r
      }

      runners.last.writer = writer
    end

    def run
      @output ||= begin
                    runners.each(&:run)
                    reader.read.tap{|std_out|
                      reader.close
                    }
                  end
    end

    def output
      run
    end

    def print
      puts output
    end
  end

  class Runner
    attr_accessor :shell_command
    attr_accessor :reader, :writer
    attr_accessor :chain, :position

    def initialize(cmd)
      @shell_command = cmd
    end

    def build_options
      {}.tap{|opts|
        opts.merge!(in: reader) if reader
        opts.merge!(out: writer) if writer
      }
    end

    def exec
      system(shell_command, build_options)
    end

    def run
      exec
      reader.close if reader
      writer.close if writer
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

