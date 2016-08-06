



class Value
  attr_reader :to_h

  def initialize(hash)
    @to_h = {}
    merge(hash)
  end

  def merge(hash)
    self.tap{|this|
      @to_h.merge!(hash)
      hash.each{|k,v|
        define_singleton_method(k){ v }

        define_singleton_method("#{k}="){|new_v|
          @to_h.merge!(k => new_v)
          define_singleton_method(k){ new_v }
        }
      }
    }
  end
  alias_method :update, :merge

  def delete(k)
    self.tap{|this|
      @to_h.delete(k)
      instance_eval(format("undef %s", k)) if respond_to?(k)
      instance_eval(format("undef %s=", k)) if respond_to?(k.to_s + ?=)
    }
  end
  alias_method :unset, :delete

  def set(k, v)
    merge(k => v)
  end

  def get(k)
    to_h[k]
  end

  def has?(k)
    respond_to?(k)
  end

  def method_missing(name, *args)
    super unless @to_h.respond_to?(name)

    @to_h.send(name, *args)
  end

  def [](key)
    get(key)
  end

  def []=(key,val)
    val.tap{
      @to_h.merge! key => val
      define_singleton_method(key){ val }
    }
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

    def new_config
      @project_config ||= Config.new(yaml_file, 'projects').tap{|configuration|
        configuration.after_read(&config_after_read)
        configuration.before_save(&config_before_save)
        configuration.read!
      }
    end

    def config_after_read
      proc{|this|
        this.data.map{|k,v|
          expanded_path = File.expand_path(v)
          dug = this.instance_variable_get(:@data)
          # dug.dig(*this.data_path)
          dug = this.data_path.inject(dug){|h,k| h[k] ||= {} }
          dug.merge!(k => expanded_path)
        }
      }
    end

    def config_before_save
      proc{|this|
        this.data.map{|k,v|
          relative_path = v.sub(%r{^(/(?:Users|home)/[^/]+)(/?)}, '~\2/').sub(%r{//+}, ?/)
          dug = this.instance_variable_get(:@data)
          # dug = dug.dig(*this.data_path)
          dug = this.data_path.inject(dug){|h,k| h[k] ||= {} } # dug.dig(*this.data_path)
          dug.merge!(k => relative_path)
        }
      }
    end

    def config
      return new_config

      # --- THIS CODE IS OLD ---
      #
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

class HeroHelper
  class << self
    def matrix_to_table(matrix)
      col_sizes = matrix.inject([]){|sizes,cols|
        cols.map.with_index{|col,i|
          cur_len = sizes[i] || 0
          new_len = col.to_s.length
          new_len > cur_len ? new_len : cur_len
        }
      }

      matrix.map{|cols|
        col_sizes.map.with_index{|csize,i|
          cols[i].to_s.ljust(csize+1).rjust(csize+2)
        }.join(?|)
      }
    end

    def string_to_underscores(str)
      str.split(/[\s_-]+/).flat_map{|part|
        part.split(/(?<=[a-z])(?=[A-Z])/)
      }.flat_map{|part|
        part.split(/(?<=[A-Z])(?=[A-Z][a-z])/)
      }.map(&:downcase).join(?_)
    end

    def string_to_classname(str)
      string = str.to_s
      string = string.sub(/^[a-z\d]*/) { |match| match.capitalize }
      string.gsub!(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{$2.capitalize}" }
      string.gsub!('/'.freeze, '::'.freeze)
      string
    end

    def edit_in_editor(*args, halt: true)
      if halt
        exec cmd_from(args.unshift(editor))
      else
        system cmd_from(args.unshift(editor))
      end
    end

    def cmd_from(*args)
      parts = args.flatten

      if parts.first[/\w\s+--?\w/i]
        cmd_with_options = parts.shift
        start_cmd = Shellwords.split(cmd_with_options)
        parts = start_cmd + parts
      end

      parts.shelljoin
    end
    alias_method :cmd_for, :cmd_from

    def system_env_vars
      { 'MANPAGER' => 'cat' }
    end

    def system_from(*args)
      system system_env_vars, cmd_from(*args)
    end
    alias_method :system_for, :system_from

    def exec_from(*args)
      exec cmd_from(*args)
    end
    alias_method :exec_for, :exec_from

    def plainify(str_or_lines)
      if str_or_lines.is_a?(Array)
        str_or_lines.map{|l| plainify(l) }
      else
        str_or_lines.gsub(/\e\S(\d+;)*\d*[mG]|.\b+/, '')
      end
    end

    def plain_from(*args)
      (output_from(*args) || '').gsub(/\e\S(\d+;)*\d*[mG]|.\b/, '')
    end
    alias_method :plain_for, :plain_from

    def plain_lines_from(*args)
      plain_from(*args).lines.map(&:chomp)
    end
    alias_method :plain_lines_for, :plain_lines_from

    def output_from(*args)
      r,w = IO.pipe
      system system_env_vars, cmd_from(*args), out: w
      w.close
      r.read.tap{|output| r.close }
    end
    alias_method :output_for, :output_from

    def output_lines_from(*args)
      output_from(*args).lines.map(&:chomp)
    end
    alias_method :output_lines_for, :output_lines_from

    class PipeCommand
      attr_accessor :cmd, :reader, :writer
      def initialize(cmd)
        @cmd = cmd
      end

      def run
        system(HeroHelper.system_env_vars, cmd,
          {}.tap{|opts|
            opts.merge!(in: reader) if reader
            opts.merge!(out: writer) if writer
          }
        ).tap{
          reader.close if reader
          writer.close if writer
        }
      end
    end

    def pipe_cmds(*cmds)
      pcmds = cmds.flatten.map(&PipeCommand.method(:new))
      return '' if cmds.empty?
      pcmds.each_cons(2).to_a.each{|b,a|
        a.reader, b.writer = IO.pipe
      }
      final_reader, pcmds.last.writer = IO.pipe
      pcmds.each(&:run)
      final_reader.read{ final_reader.close }
    end

    def mkdirs_for_file(file)
      return false if File.exist?(file)
      mkdirs File.dirname(file)
    end

    def mkdirs(dir_only)
      return false if File.exist?(dir_only)
      system system_env_vars, cmd_from('mkdir', '-pv', dir_only)
    end

    def editor
      ENV.fetch('EDITOR', 'vim')
    end

    def everything_in_dir(dir)
      Dir[File.join(dir, '**/*')]
    end

    def files_in_dir(dir)
      everything_in_dir(dir).select(&File.method(:file?))
    end

    def folders_in_dir(dir)
      everything_in_dir(dir).select(&File.method(:directory?))
    end

    def run_inside_dir(dir, &block)
      return false unless block_given?
      pwd = Dir.pwd.tap{
        Dir.chdir(dir)
      }

      block.call.tap{
        Dir.chdir(pwd)
      }
    end
  end
end


# vim: ft=ruby

class ProcessList
  class ProcessInfo < Value; end

  class << self
    def list
      @list ||= []
    end

    def running
      @running ||= []
    end

    def current
      @current = running[-1]
    end

    def finished
      @finished ||= []
    end

    def add(opts={})
      opts.merge! id: list.length, status: :running
      new_process = ProcessInfo.new(opts)
      list.push new_process
      running.push new_process
    end

    def update(opts={})
      current.update(opts)
    end

    def finalize(return_value=nil)
      finalized_process = ProcessFinalizer.finalize(current, return_value)
      finalized_process.return_value.tap{|retval|
        current.update(modified_return_value: retval,
                         # finalized_process.info.return_value,
                       status: :finished)
      }
    end

    def finish!
      finished.push running.pop
    end
  end

  class ProcessFinalizer
    class << self
      def finalize(info, return_value)
        new(info, return_value).tap(&:finalize)
      end
    end

    attr_accessor :info, :return_value
    attr_reader :object
    def initialize(info, return_value)
      @info, @return_value = info, return_value
      @object = info.object
    end

    def finalize
      info.update(
        return_value: return_value,
        status: :finalizing,
      )

      process_modifiers
      process_special_modifiers

      @info.update(return_value: @return_value)
    end

    def process_modifiers
      found = object.modifiers.map{|mod,block|
        args = ArgumentHelper.modifiers.map(&:first)
        index = args.rindex(mod)
        next if index.nil?

        arg_name, opts = arg_info = ArgumentHelper.modifiers.delete_at(index)
        [
          mod,
          Value.new(
            name: mod,
            block: block,
            info: arg_info,
            arg_name: arg_name,
            opts: opts,
          )
        ]
      }.compact.to_h

      @return_value = found.inject(@return_value){|retval,(name,handler)|
        handler.block.call(retval,*handler.opts)
      }
      @info.update(return_value: @return_value)
      @return_value
    end

    def process_special_modifiers
      found = object.special_modifiers.map{|mod,block|
        args = ArgumentHelper.modifiers.map(&:first)
        index = args.rindex(mod)
        next if index.nil?

        arg_name, opts = arg_info = ArgumentHelper.modifiers.delete_at(index)
        [
          mod,
          Value.new(
            name: mod,
            block: block,
            info: arg_info,
            arg_name: arg_name,
            opts: opts,
          )
        ]
      }.compact.to_h

      @return_value = found.inject(@return_value){|retval,(name,handler)|
        handler.block.call(retval, opts)
      }
      @info.update(return_value: @return_value)
      @return_value
    end
  end
end


class Option < Value
  class << self
    def matchable_options_from_args(args)
      args.select{|arg|
        arg[0] == ?-
      }.flat_map{|arg|
        arg[0,2] == '--' ? arg.sub(/=.*/, '') : arg.sub(/^-/, '').sub(/=.*/, '').chars.map{|c| ?- + c }
      }
    end
  end

  def toggle?
    type == :toggle
  end

  def optional_value?
    type == :optional_value
  end

  def required_value?
    type == :required_value
  end

  def used?(args)
    opt_args = option_args_for(args)
    matchers.any?{|m| opt_args.include?(m) }
  end

  def option_args_for(args)
    args.select{|arg|
      arg[0] == ?-
    }.flat_map{|arg|
      arg[0,2] == '--' ? arg.sub(/=.*/, '') : arg.sub(/^-/, '').sub(/=.*/, '').chars.map{|c| ?- + c }
    }
  end

  def process(settings)
    handler.call(settings)
  end
end


class OptionSet < Value
  class << self
    def from_name(name, &setup)
      new(name, &setup)
    end
  end

  attr_accessor :name, :setup
  def initialize(name, &setup)
    @name, @setup = name, setup

    setup.call(self)
  end

  def add_toggle(*matchers, setting: :NOT_SET, &handler)
  end
end






module ShellCommandable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    attr_accessor :subcommand, :subcommand_chain
    attr_accessor :let_blocks

    attr_accessor :arg_manager, :all_args, :modifier_args
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

    def arg_manager
      @arg_manager
    end

    def args
      arg_manager.args
    end

    def next_arg_manager
      @next_arg_manager ||= arg_manager.next
    end

    def run(arg_mgr=nil)
      if arg_mgr.is_a?(ArgumentHelper)
        @arg_manager = arg_mgr
      elsif arg_mgr
        @arg_manager = ArgumentHelper.from(arg_mgr)
      else
        @arg_manager = ArgumentHelper.next
      end

      ArgumentHelper.order.push(Value.new(name: self.name, klass: self, data: @arg_manager, manager: @arg_manager, args: @arg_manager.args))
      # @arg_manager = ArgManager.setup(passed_args)

      # @all_args = passed_args
      # @all_args ||= ARGV.clone
      # @usable_args = @all_args.take_while{|arg| arg[0] != ?@ }
      # @modifier_args = @all_args.drop_while{|arg| arg[0] != ?@ }
      # @original_args = @all_args
      @subcommand_arg = arg_manager.subcommand

      @subcommand = subcommand_matcher.match(@subcommand_arg)

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
      ProcessList.add(
        object: self,
        runner_type: runner_type,
        runner: runner,
        arg_manager: arg_manager,
        modifiers: modifiers,
        special_modifiers: special_modifiers,
      )

      if runner
        block_returned = nil
        hooks_returned = run_with_hooks{
          block_returned = runner.call
          ProcessList.update(return_value: block_returned)
          block_returned = ProcessList.finalize(block_returned)
          # block_returned = extract_and_apply_modifiers(block_returned)
        }
        ProcessList.update(hooks_return_value: hooks_returned)
        ProcessList.finish!
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
          when Array, Hash
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

    def option_sets
      @option_sets ||= {}
    end

    def load_subcommands_by_prefix(prefix)
      Dir[File.join(Dir.home, 'subcommands', format('%s-*', prefix))].each do |subcmd|
        load subcmd
      end
    end

    class OptionSet
      class << self
        def from_name(name)
          new(name)
        end
      end

      attr_accessor :name, :options
      attr_accessor :toggle_options, :value_options_with_defaults, :value_options
      def initialize(name)
        @name = name
        @toggle_options = {}
        @value_options_with_defaults = {}
        @value_options = {}
      end

      def add_option(name, *matchers, &block)
      end
    end
  end
end

