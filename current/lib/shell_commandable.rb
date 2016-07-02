
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

    def args_without_modifiers
      args.take_while{|arg| arg[0] != ?@ }
    end

    def run(passed_args=nil)
      @usable_args = passed_args if passed_args
      @original_args = args.clone
      @subcommand_arg = args.shift

      @subcommand = subcommand_matcher.match(subcommand_arg)

      route_args_and_process_command
    end

    def subcommand_proc
      @subcommand.data if @subcommand
    end

    def no_runner_proc
      Proc.new{
        print_subcommand_list
        exit 1
      }
    end

    def runner_type(code=runner)
      {}.tap{|types|
        types.merge!(subcommand_proc.object_id => format('%s (%s)', :subcommand.inspect, @subcommand.name.to_sym.inspect)) if subcommand_proc
        types.merge!(@dynamic_subcommand.object_id => :dynamic_subcommand) if @dynamic_subcommand
        types.merge!(@no_subcommand.object_id => :no_subcommand) if subcommand_proc
      }.fetch(code.object_id, :no_match_print_help_and_subcommand_list)
    end

    def runner
      @runner ||= Proc.new{
        match   = subcommand_proc
        match ||= @dynamic_subcommand if @subcommand_arg
        match ||= @no_subcommand unless @subcommand_arg
        match || no_runner_proc
      }.call
    end

    def route_args_and_process_command
      if runner
        block_returned = nil
        hooks_returned = run_with_hooks{
          block_returned = runner.call
          block_returned = extract_and_apply_modifiers(block_returned)
        }
        return block_returned
      end

      puts "Cannot figure out what to do..."
      exit 1
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

    def check_if_has_modifiers
      modifier_args.any? || special_modifier_args.any?
    end

    def has_modifiers
      @has_modifiers ||= check_if_has_modifiers
    end

    def has_modifiers!
      @has_modifiers = check_if_has_modifiers
    end

    def has_modifiers?
      has_modifiers == true
    end

    def extract_special_modifiers
      special_modifiers.keys.each do |mod|
        index = args.index(mod.to_s)
        next if index.nil?

        key = args[index]
        val = args[(index+1)..-1]
        if MainCommand.applied_modifiers.include?(key)
          next
        end
        special_modifier_args.merge!(key => val)

        has_modifiers!

        len = args[index..-1].length
        args.pop(len)
      end
    end

    def extract_modifiers
      args.reverse.take_while{|arg|
        modifiers.keys.map(&:to_s).include?(arg)
      }.tap{|mods|
        break mods if mods.empty?

        mods.each{|mod|
          if MainCommand.applied_modifiers.include?(args.last)
            args.pop
            next
          end
          modifier_args.unshift args.pop
        }

        has_modifiers!
      }
    end

    def extract_and_apply_modifiers(returned)
      extract_special_modifiers
      extract_modifiers

      has_modifiers? ? apply_modifiers(returned) : returned
    end

    def apply_modifiers(returned)
      return returned unless has_modifiers?

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
          No handler for the "#{subcommand_arg.inspect}" subcommand.

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
      @registered_special_modifiers ||= {
        "@each" => Proc.new{|returned,cmd|
          break unless returned.is_a?(Array)
          if not cmd.any?{|arg| arg[/(?<!\\)%s/i] }
            cmd.push '%s'
          end
          gsub = %r{(?<!\\)%s}i
          cmd = cmd.map{|arg| arg.gsub(gsub, '%<arg>s') }
          returned.map{|arg|
            current_command = cmd.map{|item| format(item, arg: arg.shellescape) }
            system(*current_command)
          }
        },

        "@all" => Proc.new{|returned,cmd|
          break unless returned.is_a?(Array)
          if not cmd.any?{|arg| arg[/(?<!\\)%s/i] }
            cmd.push '%s'
          end
          gsub = %r{(?<!\\)%s}i

          to_add = returned.map(&:shellescape)
          while cmdi = cmd.index('%s')
            cmd[cmdi] = to_add
            cmd = cmd.flatten
          end

          system(*cmd)
        },
      }
    end

    def modifiers
      @registered_modifiers ||= {
        "@vim" => Proc.new{|returned|
          HeroHelper.edit_in_editor *returned.flatten
        },

        "@capture" => Proc.new{|returned|
          tempfile = Tempfile.create('hero')

          case returned
          when String
            IO.write(tempfile.path, returned)
            HeroHelper.edit_in_editor(tempfile.path)
          when Array
            File.open(tempfile.path, 'w+') {|fd|
              fd.puts returned
            }
            HeroHelper.edit_in_editor(tempfile.path)
          else
            puts format('Not sure how to capture a %s...', returned.class)
          end

          tempfile.delete
          tempfile.close
        },
      }
    end

    def applied_modifiers
      @applied_modifiers ||= []
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

