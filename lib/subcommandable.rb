class SubcommandMatcher
  class << self
    def from(hash)
      new(hash)
    end
  end

  attr_accessor :subcommands
  attr_accessor :subcommand_map
  attr_accessor :subcommand_names
  def initialize(hash_or_array)
    @subcommand_map = hash_or_array
    @subcommands = hash_or_array.keys
    @subcommand_names = hash_or_array.keys
  end

  def subcommand_variations
    subcommands.inject({}) do |h,name|
      h.merge( name => name.chars.reverse.inject([]){|a,c| a.map{|tail| c + tail }.push(c) } )
    end
  end

  def uniq_variations
    subcommand_variations.inject({}){|vars,(name,list)|
      duplicate_variations  = (subcommand_names - [name]).flat_map(&subcommand_variations.method(:fetch))
      duplicate_variations -= [name]
      (list - duplicate_variations).each do |variation|
        vars.merge! variation => subcommand_map[name]
      end
      vars
    }
  end

  def match(cmd)
    uniq_variations[cmd]
  end
end



class Subcommandable
  class << self
    attr_accessor :subcommand

    def print_subcommand_list
      puts <<-MESSAGE.lines.map{|l| l.chomp.sub(/^\s{8}/, '') }
        ERROR: Subcommand required.

        Possible subcommands:
          #{subcommand_names.join("\n  ")}
      MESSAGE
    end

    def run_with_hooks(&block)
      @before_hook.call if @before_hook
      block.call
      @after_hook.call if @after_hook
    end

    def run(args=argv)
      @args = args || argv
      @subcommand ||= args.shift

      if @subcommand.nil?
        if @no_subcommand.present?
          run_with_hooks{ @no_subcommand.call }
          exit 0
        else
          print_subcommand_list
          exit 1
        end
      end

      @runner ||= subcommand_matcher.match(@subcommand)

      if @runner
        run_with_hooks{ @runner.call }
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
      SubcommandMatcher.new subcommands
    end

    def subcommand_names
      @subcommands.keys
    end

    def subcommands
      @subcommands ||= {}
    end

    def fallback_runner
      @fallback_runner ||= Proc.new do
        puts format('No handler for the "%s" subcommand', subcommand.inspect)
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

    def register_subcommand(name, &block)
      subcommands.merge!( name.to_s => block ).tap{|cmds|
      # @headers_printed ||= []
      #unless @headers_printed.include?(self)
      #  puts
      #  puts format('Class Name: %s', self.name)
      #  puts format('Registered subcommand: %s', name)
      #  puts
      #  puts format('  Subcommand Names:', name)

      #  @headers_printed.push(self)
      #end
      #puts format('    %s', name)
      }
    end

    def load_subcommands_by_prefix(prefix)
      Dir[File.join(Dir.home, 'subcommands', format('%s-*', prefix))].each do |subcmd|
        load subcmd
      end
    end
  end
end
