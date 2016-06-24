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
