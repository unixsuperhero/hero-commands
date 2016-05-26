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


class Config
  attr_accessor :file, :data_path

  def initialize(file, *data_path)
    @file, @data_path = file, data_path
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
    @data = YAML.load(yaml_data) || {}
    Hash.make_endless(@data)
  end

  def read
    @data || read!
  end

  def save
    IO.write yaml_file, YAML.dump(@data)
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
