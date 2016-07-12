
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




