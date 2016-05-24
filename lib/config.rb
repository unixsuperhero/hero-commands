require 'yaml'

require './lib/hash_ext'

class HashHelper
  class << self
    def endless_proc
      Proc.new do |h,k|
        h[k] = Hash.new(&endless_proc)
      end
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
    HashHelper.make_endless(@data)
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
