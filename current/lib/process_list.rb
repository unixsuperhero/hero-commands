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
