
class NameMatcherRewrite
  attr_accessor :name_map, :names
  attr_accessor :grouped_by_values, :name_groups, :partials

  def initialize(hash)
    @name_map = hash
    @names = hash.keys
    @grouped_by_values = @name_map.group_by{|k,v| v }
    @name_groups = @grouped_by_values.flat_map{|k,names| names.map{|name| [name, names] } }.to_h
    @partials = @names.map{|name| [name, partials_for(name)] }.to_h
  end

  def partials_for(str)
    str.chars.inject([]) do |arr,c|
      arr.push((arr.last || '') + c)
    end
  end

  def uniq_partials
    @uniq_partials ||= names.map{|name|
      other_partials = (names - name_groups[name]).flat_map{|oname| partials[oname] }.sort.uniq
      other_partials -= [name]
      [name, partials[name] - other_partials]
    }.to_h
  end

  def shortest_partials
    @shortest_partials ||= names.map{|name|
      [name, uniq_partials[name].min_by(&:length)]
    }.to_h
  end

  def usages
    @usages ||= names.map{|name|
      shortest = shortest_partials[name]
      next [name,name] if shortest == name
      [name, format('%s[%s]', name[0,shortest.length], name[(shortest.length - 1)..-1])]
      # l,r = name.split(/(?<=^#{shortest_partials[name]})/)
    }.to_h
  end

  def info
    @info ||= names.map{|name|
      [
        name,
        {}.tap{|h|
          h.merge!(name: name)
          h.merge!(data: name_map[name])
          h.merge!(similar_names: name_groups[name])
          h.merge!(partials: partials[name])
          h.merge!(matching_partials: uniq_partials[name])
          h.merge!(shortest_partial: shortest_partials[name])
          h.merge!(syntax: usages[name])
          h.merge!(usage: usages[name])
        }
      ]
    }.to_h
  end

  def match(str)
    info.find{|name,info|
      next unless info[:matching_partials].include?(str)
      return info
    }
  end
end

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

require 'yaml'

class Hash
  class << self
    def endless_proc
      Proc.new do |h,k|
        h[k] = Hash.new(&endless_proc)
      end
    end

    def endless
      Hash.new(&endless_proc)
    end

    def make_endless(hash)
      hash.tap do |h|
        h.default_proc = endless_proc
        h.each do |k,v|
          next unless v.is_a?(Hash)
          h[k] = make_endless(v)
        end
      end
    end

    def with_default(default_value)
      Hash.new{|h,k| h[k] = default_value.clone }
    end
  end

  def select_keys(*keys)
    dup.select{|k,v| keys.include?(k) }
  end
  alias_method :pluck, :select_keys
  alias_method :slice, :select_keys
  alias_method :subset, :select_keys

  def deep_merge(other_hash, &block)
    dup.deep_merge!(other_hash, &block)
  end

  def deep_merge!(other_hash, &block)
    other_hash.each_pair do |current_key, other_value|
      this_value = self[current_key]

      self[current_key] = if this_value.is_a?(Hash) && other_value.is_a?(Hash)
        this_value.deep_merge(other_value, &block)
      else
        if block_given? && key?(current_key)
          block.call(current_key, this_value, other_value)
        else
          other_value
        end
      end
    end

    self
  end
end


# vim: ft=ruby

class Config
  attr_accessor :file, :data_path
  attr_accessor :before_save_hooks, :after_save_hooks
  attr_accessor :before_read_hooks, :after_read_hooks

  def initialize(file, *data_path)
    @file, @data_path = file, data_path
    @before_read_hooks = []
    @after_read_hooks = []
    @before_save_hooks = []
    @after_save_hooks = []
  end

  def clear_before_read_hooks!
    @before_read_hooks = []
  end

  def clear_after_read_hooks!
    @after_read_hooks = []
  end

  def clear_before_save_hooks!
    @before_save_hooks = []
  end

  def clear_after_save_hooks!
    @after_save_hooks = []
  end

  def before_read(&block)
    return unless block_given?
    @before_read_hooks.push(block)
  end

  def after_read(&block)
    return unless block_given?
    @after_read_hooks.push(block)
  end

  def before_save(&block)
    return unless block_given?
    @before_save_hooks.push(block)
  end

  def after_save(&block)
    return unless block_given?
    @after_save_hooks.push(block)
  end

  def yaml_file
    @file #File.join(Dir.home, 'rippers.yml')
  end

  # def yaml_outfile
  #   File.join(Dir.home, 'rippers.yml')
  # end

  def yaml_data
    IO.read yaml_file
  end

  def read!
    before_read_hooks.map{|hook| hook.call(self) }
    @data = YAML.load(yaml_data) || {}
    after_read_hooks.map{|hook| hook.call(self) }
    Hash.make_endless(@data)
  end

  def read
    @data || read!
  end

  def save
    before_save_hooks.map{|hook| hook.call(self) }
    IO.write yaml_file, YAML.dump(@data)
    after_save_hooks.map{|hook| hook.call(self) }
    read!
  end

  def write
    save
  end

  def update(vals={})
    data.clear.merge!(vals)
  end

  def merge(vals={})
    data.deep_merge!(stringify_keys vals)
  end

  def stringify_keys(vals={})
    vals.tap do |strs|
      vals.keys.select{|k|
        k.is_a?(Symbol) && not(k.is_a?(String))
      }.each do |k|
        strs.merge!(k.to_s => strs.delete(k))
      end
    end
  end

  def all_data
    read
  end

  def data
    return all_data if data_path == []
    data_path.inject(all_data){|result,key|
      # result.merge!(key => result.fetch(key, {}))[key]
      result[key]
    }
  end
end


# vim: ft=ruby

class Tmux
  class << self
    def sessions
      `tmux ls`.lines.select{|l| l[/^[^:]+:\s+\d/i] }.map{|l| l[/^([^:]+)(?=:\s+\d+)/i] }
    end

    def session_exists?(name)
      sessions.include?(name)
    end

    def attach_to_session(name)
      exec("tmux a -t #{name}")
    end

    def new_session(name, path=Dir.pwd, *args)
      exec("tmux new -s #{name} -c #{path} " + args.join(' '))
    end
  end
end


# vim: ft=ruby


class ProjectHelper
  class << self
    def project_for(partial)
      partial = partial[1..-1] if partial[0] == ?@
      project_matcher.match_with_data(partial)
    end

    def config
      Config.new(yaml_file, 'projects').tap{|configuration|
        configuration.after_read do |this|
          this.data.map{|k,v|
            expanded_path = File.expand_path(v)
            dug = this.instance_variable_get(:@data)
            dug = dug.dig(*this.data_path)
            dug.merge!(k => expanded_path)
          }
        end

        configuration.before_save do |this|
          this.data.map{|k,v|
            relative_path = v.sub(%r{^(/(?:Users|home)/[^/]+)(/?)}, '~\2/').sub(%r{//+}, ?/)
            dug = this.instance_variable_get(:@data)
            dug = dug.dig(*this.data_path)
            dug.merge!(k => relative_path)
          }
        end
        configuration.read!
      }
    end

    def project_matcher
      NameMatcher.from(config.data)
    end

    def yaml_file
      File.join(Dir.home, 'projects.yml')
    end

    def is_project?(partial)
      full_name = project_matcher.match_name(partial)
    end

    def projects
      config.data.keys
    end

    def dir_for(project_partial)
      project_matcher.match(project_partial)
    end

    def dirs
      config.data.values
    end

    def tmux_session_for_project(project_name)
      name = project_matcher.match_name(project_name)
      path = project_matcher.match(project_name)

      error_exit('No project found matching "%s"...' % project_name) unless name

      puts
      puts format('Project Name: %s', name)
      puts format('Project Path: %s', path)
      puts

      if Tmux.session_exists?(name)
        Tmux.attach_to_session(name)
      else
        Tmux.new_session(name, path)
      end
    end
  end
end

