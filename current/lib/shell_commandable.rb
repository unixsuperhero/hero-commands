
module ShellCommandable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    attr_accessor :subcommand, :subcommand_chain
    attr_accessor :let_blocks

    attr_accessor :original_args, :usable_args
    attr_accessor :args_with_subcommand, :args_without_subcommand
    attr_accessor :subcommand_arg

    def args_with_subcommand
      [subcommand] + usable_args
    end

    def args_without_subcommand
      usable_args
    end

    def route_args_and_process_command
      if @subcommand
        ap(in: :@subcommand_block)
        block_returned = nil
        hooks_returned = run_with_hooks{
          block_returned = @subcommand.call
          block_returned = apply_modifiers(block_returned)
        }
        return block_returned
      elsif @subcommand_arg && @dynamic_subcommand
        ap(in: :@dynamic_subcommand_block)
        block_returned = nil
        hooks_returned = run_with_hooks{
          block_returned = @dynamic_subcommand.call
          block_returned = apply_modifiers(block_returned)
        }
        return block_returned
      elsif @subcommand_arg.nil? && @no_subcommand
        ap(in: :@no_subcommand_block)
        block_returned = nil
        hooks_returned = run_with_hooks{
          block_returned = @no_subcommand.call
          block_returned = apply_modifiers(block_returned)
        }
        return block_returned
      else
        ap(in: :@print_subcommand_list)
        print_subcommand_list
        exit 1
      end
    end

    # def old_route_args_and_process_command
    #   # OLD VERSION

    #   if @subcommand.nil?
    #     if @no_subcommand.is_a?(Proc)
    #       block_returned = nil
    #       hooks_returned = run_with_hooks{
    #         block_returned = @no_subcommand.call
    #         block_returned = apply_modifiers(block_returned)
    #       }
    #       return block_returned
    #     else
    #       print_subcommand_list
    #       exit 1
    #     end
    #   end

    #   # if @subcommand.index(?:) && @subcommand.index(?:) > 0
    #   #   @subcommand, @subcommand_chain = @subcommand.split(?:, 2)
    #   # end

    #   # @runner = @subcommand # subcommand_matcher.match(@subcommand)

    #   if @subcommand
    #     block_returned = nil
    #     hooks_returned = run_with_hooks{
    #       block_returned = @subcommand.data.call
    #       block_returned = apply_modifiers(block_returned)
    #     }
    #     return block_returned

    #     # TODO: figure out how to pass specific args to a subcmd in the middle
    #     #       of the chain...we could do something like subcmdname:value
    #     #       so for example: h git branch:checkout feature.date.autoparser checkout:master
    #     #
    #     #       maybe instead of using just the subcmd arg to specify what is
    #     #       chained in the same handler, use a separator that sits between
    #     #       where one set of args end and next subcmd begins like '\;'
    #     #       because it is escaped...it shouldn't interfere with bash or zsh
    #     #       (and find uses it)
    #     ## if @subcommand_chain
    #     ##   if command_output
    #     ##     if command_output.is_a?(Array)
    #     ##       run([@subcommand_chain] + command_output)
    #     ##     else
    #     ##       run([@subcommand_chain, command_output])
    #     ##     end
    #     ##   else
    #     ##     run([@subcommand_chain])
    #     ##   end
    #     ## end

    #     exit 0
    #   end

    #   if @dynamic_subcommand
    #     block_returned = nil
    #     hooks_returned = run_with_hooks{
    #       block_returned = @dynamic_subcommand.call
    #       block_returned = apply_modifiers(block_returned)
    #     }
    #     return block_returned
    #   end
    # end

    def run(passed_args=nil)
      @usable_args = passed_args if passed_args
      @original_args = args.clone
      @subcommand_arg = args.first

      @subcommand = subcommand_matcher.match(subcommand_arg)

      # ap(before: 'extract',
      #    original_args: @original_args,
      #    usable_args: @usable_args,
      #    args: args,
      #    subcmd_query: @subcommand_arg,
      #    subcmd: @subcommand,
      #    args_without_subcommand: @args_without_subcommand,
      #    args_with_subcommand: @args_with_subcommand,
      #   )

      if @subcommand
        args.shift
      end

      extract_special_modifiers
      extract_modifiers

      # ap(in: self.name, args: args, subcommand_name: @subcommand && @subcommand.name, has_modifiers?: has_modifiers?)

      route_args_and_process_command

      # # puts format('Runner/handler not found for the "%s" subcommand', subcommand)
      # print_subcommand_list
      # exit 1
    end

    def let_blocks
      @let_blocks ||= {}
    end

    def let(name, &block)
      let_blocks.merge!(name => block)
      define_singleton_method(name, &block)
    end

    def special_modifier_args
      @special_modifier_args ||= {}
    end

    def modifier_args
      @modifier_args ||= []
    end

    def has_modifiers
      @has_modifiers ||= false
    end

    def has_modifiers!
      @has_modifiers = true
    end

    def has_modifiers?
      @has_modifiers == true
    end

    def extract_special_modifiers
      special_modifiers.keys.each do |mod|
        index = args.index(mod.to_s)
        next if index.nil?

        has_modifiers!

        key = args[index]
        val = args[(index+1)..-1]
        special_modifier_args.merge!(key => val)

        len = args[index..-1].length
        args.pop(len)
      end
    end

    def extract_modifiers
      args.reverse.take_while{|arg|
        modifiers.keys.map(&:to_s).include?(arg)
      }.tap{|mods|
        break mods if mods.empty?

        has_modifiers!

        mods.each{|mod|
          modifier_args.unshift args.pop
        }
      }
    end

    def apply_modifiers(returned)
      if special_modifier_args.keys.any?
        returned = special_modifier_args.keys.inject(returned) do |retval,smod|
          cmd = special_modifier_args[smod]
          special_modifiers[smod].call(retval, cmd)
        end
      end

      if modifier_args.any?
        returned = modifier_args.inject(returned) do |retval,mod|
          modifiers[mod].call(retval)
        end
      end

      returned
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
      @current_project ||= Proc.new{
        pwd = Dir.pwd
        possible_projects = ProjectHelper.projects.select{|name,dir|
          pwd.start_with?(dir)
        }

        return if possible_projects.empty?
        name,dir = possible_projects.max_by{|name,dir| dir.length }
        ProjectHelper.project_for(name)
      }.call
    end

    def args
      @usable_args ||= ARGV.clone
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

    def special_modifiers
      @registered_special_modifiers ||= {}
    end

    def modifiers
      @registered_modifiers ||= {}
    end

    def register_special_modifier(*names, &block)
      names.each{|name| special_modifiers.merge!( name.to_s => block ) }
    end

    def register_modifier(*names, &block)
      names.each{|name| modifiers.merge!( name.to_s => block ) }
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

