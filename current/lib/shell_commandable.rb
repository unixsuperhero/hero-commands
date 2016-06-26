
module ShellCommandable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    attr_accessor :subcommand, :subcommand_chain

    def let(name, &block)
      define_singleton_method(name, &block)
    end

    def run(args=ARGV.clone)
      @args = args
      @subcommand = args.shift

      if @subcommand.nil?
        if @no_subcommand.is_a?(Proc)
          block_returned = nil
          hooks_returned = run_with_hooks{
            block_returned = @no_subcommand.call
          }
          ap(
            hooks_returned: hooks_returned,
            block_returned: block_returned,
          )
          return block_returned
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
        block_returned = nil
        hooks_returned = run_with_hooks{
          block_returned = @runner.data.call
        }
        ap(
          hooks_returned: hooks_returned,
          block_returned: block_returned,
        )
        return block_returned

        # TODO: figure out how to pass specific args to a subcmd in the middle
        #       of the chain...we could do something like subcmdname:value
        #       so for example: h git branch:checkout feature.date.autoparser checkout:master
        #
        #       maybe instead of using just the subcmd arg to specify what is
        #       chained in the same handler, use a separator that sits between
        #       where one set of args end and next subcmd begins like '\;'
        #       because it is escaped...it shouldn't interfere with bash or zsh
        #       (and find uses it)
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
        block_returned = nil
        hooks_returned = run_with_hooks{
          block_returned = @dynamic_subcommand.call
        }
        ap(
          hooks_returned: hooks_returned,
          block_returned: block_returned,
        )
        return block_returned
      end

      puts format('Runner/handler not found for the "%s" subcommand', subcommand)
      exit 1
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

    def current_project
      @current_project ||= begin
        pwd = Dir.pwd
        possible_projects = ProjectHelper.projects.select{|name,dir|
          pwd.start_with?(dir)
        }

        return if possible_projects.empty?
        name,dir = possible_projects.max_by{|name,dir| dir.length }
        ProjectHelper.project_for(name)
      end
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

