
module ShellCommandable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    attr_accessor :subcommand, :subcommand_chain

    def let(name, &block)
      define_singleton_method(name, &block)
    end

    def error_exit(msg=nil, &block)
      puts format('ERROR: %s', msg) if msg

      block.call if block_given?

      exit 1
    end

    def print_subcommand_list
      puts <<-MESSAGE.lines.map{|l| l.chomp.sub(/^\s{8}/, '') }
        ERROR: Subcommand required.

        Possible subcommands:
          #{subcommand_matcher.usages.values.join("\n  ")}
      MESSAGE
    end

    def run_with_hooks(&block)
      @before_hook.call if @before_hook
      block.call
      @after_hook.call if @after_hook
    end

    def run(args=ARGV.clone)
      @args = args
      @subcommand = args.shift

      if @subcommand.nil?
        if @no_subcommand.is_a?(Proc)
          run_with_hooks{ @no_subcommand.call }
          exit 0
        else
          print_subcommand_list
          exit 1
        end
      end

      if @subcommand.index(?:) && @subcommand.index(?:) > 0
        @subcommand, @subcommand_chain = @subcommand.split(?:, 2)
      end

      @runner = subcommand_matcher.match(@subcommand)

      if @runner
        command_output = nil
        run_with_hooks{ command_output = @runner.data.call }

        if @subcommand_chain
          if command_output
            if command_output.is_a?(Array)
              run([@subcommand_chain] + command_output)
            else
              run([@subcommand_chain, command_output])
            end
          else
            run([@subcommand_chain])
          end
        end

        exit 0
      end

      if @dynamic_subcommand
        run_with_hooks{ @dynamic_subcommand.call }
        exit 0
      end

      puts format('Runner/handler not found for the "%s" subcommand', subcommand)
      exit 1
    end

    def args
      argv
    end

    def argv
      @args ||= ARGV.clone
    end

    def subcommand_matcher
      NameMatcher.new subcommands
    end

    def subcommand_names
      subcommand_matcher.names
    end

    def subcommands
      @subcommands ||= {}
    end

    def fallback_runner
      @fallback_runner ||= Proc.new do
        puts <<-MESSAGE.lines.map{|l| l.chomp.sub(/^\s{10}/, '') }
          No handler for the "#{subcommand.inspect}" subcommand.

          These are the possible subcommands:
            #{subcommand_matcher.syntax.values.join("\n  ")}
        MESSAGE
        exit 1
      end
    end

    def before(&block)
      @before_hook = block
    end

    def after(&block)
      @after_hook = block
    end

    def default_handler(&block)
      @no_subcommand = @dynamic_subcommand = block
    end

    def no_subcommand(&block)
      @no_subcommand = block
    end

    def dynamic_subcommand(&block)
      @dynamic_subcommand = block
    end

    def register_subcommand(*names, &block)
      names.each{|name| subcommands.merge!( name.to_s => block ) }
    end

    def load_subcommands_by_prefix(prefix)
      Dir[File.join(Dir.home, 'subcommands', format('%s-*', prefix))].each do |subcmd|
        load subcmd
      end
    end
  end
end

