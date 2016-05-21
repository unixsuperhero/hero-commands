require 'yaml'

require './lib/hash_ext'

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
      result.merge!(key => result.fetch(key, {}))[key]
    }
  end
end
