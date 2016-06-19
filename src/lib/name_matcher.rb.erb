class NameMatcher
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

  def uniqs_by_name
    deletes = []
    subcommand_map.inject({}){|h,(k,v)|
      h.tap do |new_map|
        list_for(k).each do |e|
          if h.has_key?(e)
            deletes.push(e) if subcommand_map[h[e]] != subcommand_map[k]
          else
            new_map.merge!(e => k)
          end
        end
      end
    }.tap{|uniq_map|
      deletes.each{|k| uniq_map.delete(k) }
    }.merge(Hash[subcommand_names.zip(subcommand_names)])
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

  def match_with_data(partial)
    return unless uniqs.has_key?(partial)
    {}.tap{|data|
      full_name = match_name(partial)
      data.merge!(
        name: full_name,
        data: uniqs[partial],
        syntax: syntax[full_name],
        # syntax
        # array of uniq matches
      )
    }
  end
end
