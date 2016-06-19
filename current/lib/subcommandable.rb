class SubcommandMatcher
  class << self
    def from(hash)
      new(hash)
    end

    def list_for(str)
      str.chars.inject([]) do |arr,c|
        arr.push((arr.last || '') + c)
      end
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

  def list_for(str)
    self.class.list_for(str)
  end

  def name_map
    deletes = []
    subcommand_map.inject({}){|h,(k,v)|
      h.tap do |new_map|
        list_for(k).each do |e|
          if h.has_key?(e)
            deletes.push(e) if h[e] != v
          else
            new_map.merge!(e => k)
          end
        end
      end
    }.tap{|uniq_map|
      deletes.each{|k| uniq_map.delete(k) }
    }.merge(Hash[ subcommand_names.zip(subcommand_names) ])
  end

  def uniqs
    deletes = []
    subcommand_map.inject({}){|h,(k,v)|
      h.tap do |new_map|
        list_for(k).each do |e|
          if h.has_key?(e)
            deletes.push(e) if h[e] != v
          else
            new_map.merge!(e => v)
          end
        end
      end
    }.tap{|uniq_map|
      deletes.each{|k| uniq_map.delete(k) }
    }.merge(subcommand_map)
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

  def shortest_variations
    sorted_uniqs = uniqs.keys.sort_by(&:length)
    subcommand_names.inject({}){|h,name|
      h.merge(
        name => sorted_uniqs.find{|uniq_name|
          next false if subcommand_names.include?(uniq_name) && name != uniq_name
          name.start_with?(uniq_name)
        }
      )
    }
  end

  def simple_syntax_for(full,abbr)
    return abbr if abbr == full
    right = full.slice(abbr.length, full.length)
    format('%s[%s]', abbr, right)
  end

  def complex_syntax_for(full,abbr)
    left,right = full.slice(0, abbr.length), full.slice(abbr.length, full.length)
    return right.chars.inject(abbr.dup){|syn,c| syn.dup.concat(?[.dup).concat(c.dup) }.concat(?].dup * right.dup.length)
    format('%s%s%s', abbr,
                     right.chars.map{|c| ?[ + c }.join,
                     ?] * right.length)
  end

  def syntax_formats
    shortest_variations.map{|full,abbr|
      # optional = full.slice(abbr.length, full.length)
      {
        full => {
          simple: simple_syntax_for(full, abbr), # format('%s[%s]', abbr, optional),
          complex: complex_syntax_for(full, abbr), # format('%s%s', abbr, optional.chars.map{|c| ?[ + c }.push(?] * optional.length).join),
        }
      }
    }.inject(:merge)
  end

  def syntax(type=:simple)
    type = :simple unless type.respond_to?(:to_sym) && %i[ simple complex ].include?(type.to_sym)
    syntax_formats.map{|k,h| { k => h[type.to_sym] } }.inject(:merge)
    # shortest_variations.map{|full,abbr|
    #   optional = full.slice(abbr.length, full.length)
    #   { full => format('%s[%s]', abbr, optional) }
    # }.inject(:merge)
  end
  alias_method :print_format, :syntax

  def match_name(partial)
    name_map[partial]
  end

  def match(cmd)
    uniqs[cmd]
  end
end


module LetHelper
  def self.let(name, &block)
    define_method(name, &block)
  end
end

module ShellCommandable
  def self.included(base)
    base.extend(ClassMethods)
  end

  def let(name, &block)
    define_method(name, &block)
  end

  module ClassMethods
    attr_accessor :subcommand

    def error_exit(msg=nil, &block)
      puts format('ERROR: %s', msg) if msg

      block.call if block_given?

      exit 1
    end

    def print_subcommand_list
      puts <<-MESSAGE.lines.map{|l| l.chomp.sub(/^\s{8}/, '') }
        ERROR: Subcommand required.

        Possible subcommands:
          #{subcommand_matcher.syntax.values.join("\n  ")}
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
        if @no_subcommand.is_a?(Proc)
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

class Subcommandable
  class << self
    attr_accessor :subcommand

    def inherited(base)
      base.extend LetHelper
    end

    def error_exit(msg=nil, &block)
      puts format('ERROR: %s', msg) if msg

      block.call if block_given?

      exit 1
    end

    # def let(attr_name, &block)
    #   return unless block_given?
    #   attr_name = attr_name.to_sym unless attr_name.is_a?(Symbol)
    #   define_singleton_method(attr_name, block)
    # end

    def print_subcommand_list
      puts <<-MESSAGE.lines.map{|l| l.chomp.sub(/^\s{8}/, '') }
        ERROR: Subcommand required.

        Possible subcommands:
          #{subcommand_matcher.syntax.values.join("\n  ")}
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
        if @no_subcommand.is_a?(Proc)
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


# vim: ft=ruby
