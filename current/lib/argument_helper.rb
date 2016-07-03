


class Value
  attr_reader :default
  def initialize(hash, default: nil)
    merge hash
    @default = default
  end

  def merge(hash)
    singleton.send(:attr_accessor, *hash.keys.map(&:to_sym))
    hash.each{|k,v| instance_variable_set("@#{k}", v) }
  end
  alias_method :update, :merge

  def method_missing(name, *args)
    (default.is_a?(Numeric) || default.is_a?(NilClass)) ? default : default.dup
  end

  private def singleton
    instance_eval('class << self; self; end')
  end
end


class NameMatcher
  attr_accessor :name_map, :names

  def initialize(hash)
    @name_map = hash
    @names = hash.keys
  end

  def grouped_by_values
    @grouped_by_values ||= name_map.map{|k,v|
      [v, names.select{|oname| name_map[oname] == v }]
    }
  end

  def name_groups
    @name_groups ||= grouped_by_values.inject({}){|h,(k,grouped_names)|
      grouped_names.map{|name| h.merge!(name => grouped_names) }
      h
    }
  end

  def partials
    @partials ||= names.map{|name| [name, partials_for(name)] }.to_h
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
      [name, format('%s[%s]', name[0,shortest.length], name[(shortest.length)..-1])]
    }.to_h
  end

  def info
    @info ||= names.map{|name|
      [
        name,
        Value.new(
          name: name,
          data: name_map[name],
          similar_names: name_groups[name],
          partials: partials[name],
          matching_partials: uniq_partials[name],
          shortest_partial: shortest_partials[name],
          syntax: usages[name],
          usage: usages[name],
        )
      ]
    }.to_h
  end

  def match(str)
    found = info.find{|name,info| info.matching_partials.include?(str) }
    found.last if found
  end

  def match_name(str)
    found = info.find{|name,info| info.matching_partials.include?(str) }
    found.first if found
  end

  def match_data(str)
    found = info.find{|name,info| info.matching_partials.include?(str) }
    found.last.data if found
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
      result[key]
    }
  end
end


# vim: ft=ruby

class Tmux
  class << self
    def sessions(*patterns)
      list = HeroHelper.output_lines_from(*'tmux ls'.shellsplit).select{|l|
        l[/^\S[^:]*:/]
      }.map{|l|
        l.sub(/:.*/, '')
      }.compact

      return list if patterns.empty?

      ListFilter.run(list, *patterns)
    end

    def commands(*patterns)
      hash = HeroHelper.output_lines_from(*'tmux list-commands'.shellsplit).map{|l|
        [ l[/\S+/], l ]
      }.to_h

      return hash if patterns.empty?

      list = ListFilter.run(hash.keys, *patterns)
      list.map{|key| [ key, hash[key] ] }.to_h
    end

    def keys(*patterns)
      list = HeroHelper.output_lines_from(*'tmux list-keys'.shellsplit).map{|l|
        l.scan(/^(bind-key)\s*(-r)?\s*(-T\s\s*\S\S*)\s*(\S+)\s*(\S.*)$/i).flatten #(?:\s*-+\w+)+\s*(?=\S)(?!-))(\S+\s+\S+)(?:\s*(\S.*))?$/)
      }

      return list if patterns.empty?

      matches = ListFilter.run(list, *patterns){|item|
        item[3]
      }

      matches = ListFilter.run(list, *patterns){|item|
        item[3..-1].join(' ')
      } if matches.empty?

      return matches if matches.empty?

      HeroHelper.matrix_to_table(matches)
    end

    def windows(*patterns)
      list = HeroHelper.output_lines_from(*'tmux list-windows'.shellsplit)

      return list if patterns.empty?

      ListFilter.run(list, *patterns)
    end

    def panes(*patterns)
      list = HeroHelper.output_lines_from(*'tmux list-panes'.shellsplit)

      return list if patterns.empty?

      ListFilter.run(list, *patterns)
    end

    def buffers(*patterns)
      list = HeroHelper.output_lines_from(*'tmux list-buffers'.shellsplit)

      return list if patterns.empty?

      ListFilter.run(list, *patterns)
    end

    def clients(*patterns)
      list = HeroHelper.output_lines_from(*'tmux list-clients'.shellsplit)

      return list if patterns.empty?

      ListFilter.run(list, *patterns)
    end

    def session_exists?(name)
      sessions.include?(name)
    end

    def switch_to_session(name)
      exec("tmux switchc -t #{name}")
    end

    def attach_to_session(name)
      exec("tmux a -t #{name}")
    end

    def new_session(name, path=Dir.pwd, *args)
      exec("tmux new -s #{name} -c #{path} " + args.join(' '))
    end

    def new_detached_session(name, path=Dir.pwd)
      system("tmux new -d -s #{name.shellescape} -c #{path.shellescape}")
    end

    def in_tmux?
      ENV.has_key?('TMUX')
    end

    def join_new_session(name, path=Dir.pwd)
      if in_tmux?
        new_detached_session(name, path)
        switch_to_session(name)
      else
        new_session(name, path)
      end
    end

    def join_existing_session(name, path=Dir.pwd)
      if in_tmux?
        switch_to_session(name)
      else
        attach_to_session(name)
      end
    end

    def force_session(name, path=Dir.pwd, *args)
      if session_exists?(name)
        join_existing_session(name)
      else
        join_new_session(name, path)
      end
    end
  end
end


# vim: ft=ruby


class ProjectHelper
  class << self
    def projects
      config.data
    end

    def project_names
      config.data.keys
    end

    def project_dirs
      config.data.values
    end

    def project_for(partial)
      partial = partial[1..-1] if partial[0] == ?@
      project_matcher.match(partial).tap{|proj|
        proj.merge(dir: proj.data) unless proj.nil?
      }
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
      NameMatcher.new(config.data)
    end

    def yaml_file
      File.join(Dir.home, 'projects.yml')
    end

    def is_project?(partial)
      project_for(partial).is_a?(Value)
    end

    def dir_for(project_partial)
      m = project_for(project_partial)
      m.data if m
    end

    def tmux_session_for_project(project_name)
      proj = project_for(project_name)

      error_exit('No project found matching "%s"...' % project_name) unless proj

      name = proj.name
      path = proj.data

      puts
      puts format('Project Name: %s', name)
      puts format('Project Path: %s', path)
      puts

      Tmux.force_session(name, path)
    end
  end
end



class ArgumentHelper
  class << self
    attr_reader :original_args
    attr_accessor :project_arg, :project
    attr_accessor :all_args, :args, :modifier_args
    attr_accessor :order, :applied_modifiers

    def init(list=ARGV.clone)
      return from(list) if @original_args

      @original_args = list.clone

      if list.first && list.first[0] == ?@
        @project = ProjectHelper.project_for(list.first)
        @project_arg = list.shift if @project
      end

      @all_args = list
      @args = list.take_while{|arg| arg[0] != ?@ }
      @modifier_args = list.drop_while{|arg| arg[0] != ?@ }

      @order = []
      @applied_modifiers = []

      from(args)
    end

    def modifiers
      return [] if @modifier_args.nil? || @modifier_args.empty?

      @modifiers ||= @modifier_args.inject([]){|list,arg|
        if arg[0] == ?@
          list.push [arg, []]
        else
          current = list.pop
          current.last.push arg
          list.push current
        end
      }
    end

    def from(list=ARGV.clone)
      if @original_args.nil?
        init(list)
      else
        new(list)
      end
    end

    def next
      if order.empty?
        init
      else
        order.last.manager.next
      end
    end
  end

  attr_accessor :originals
  attr_accessor :subcommand
  attr_accessor :all_args, :args

  def initialize(list=ARGV.clone)
    @originals = list.clone
    @all_args = list.clone
    @subcommand = list.shift
    @args = list
  end

  def next
    @next_manager ||= self.class.from(args)
  end
end
