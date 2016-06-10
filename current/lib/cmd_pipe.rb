
class CmdPipe
  attr_accessor :commands, :pipes, :options
  def initialize(*args)
    @options = args.last.is_a?(Hash) ? args.pop : {}
    @commands = args.flatten.map{|cmd| Command.new(cmd) }
    @pipes = Pipe.from_commands(@commands)
  end

  def start
    @commands.reverse.each(&:start)
  end

  def statuses
    @commands.map(&:status)
  end

  def stop
    @commands.each(&:stop)
    @commands.each(&:kill)
  end

  class Pipe
    class << self
      def all
        @all_pipes ||= []
      end

      def from_commands(*commands)
        (commands.flatten.count - 1).
          times.
          flat_map{ IO.pipe }.
          push(nil).
          reverse.
          push(nil).
          each_slice(2).
          map{|rw| new(*rw) }.
          tap{|new_pipes|
            commands.flatten.zip(new_pipes).each{|cmd,pipe|
              cmd.pipe = pipe
              pipe.command = cmd
            }
          }
      end
    end

    attr_reader :reader, :writer
    attr_reader :input, :output
    attr_reader :closed
    attr_accessor :command
    def initialize(r=nil, w=nil)
      @reader, @writer = r, w
      @input, @output = r, w
      @closed = false
      self.class.all.push self
    end

    def close
      return if closed
      writer.close if writer
      reader.close if reader
      @closed = true
    end
  end

  class Command
    class << self
      def all
        @all_commands ||= []
      end
    end

    attr_accessor :cmd, :options
    attr_accessor :pid, :active
    attr_accessor :pipe

    def initialize(cmd, options={})
      @cmd, @options = cmd, options
      self.class.all.push self
    end

    def build_options
      @options.tap do |opts|
        opts.merge! in: @pipe.reader if @pipe.reader
        opts.merge! out: @pipe.writer if @pipe.writer
      end
    end

    def start
      return if @active == false
      @pid = spawn(cmd, build_options)
      @active = true
      @killed = false
    end

    def status
      #Process.wait2(pid)
    end

    def stop
      return unless @active == true
      pipe.close
      @active = false
    end

    def kill
      return
      return if @killed == true
      # Process.detach(pid)
      Process.kill(:KILL, pid)
      @killed = true
    end
  end
end

