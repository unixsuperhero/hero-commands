#!/usr/bin/env ruby

require 'subcommandable'

class MainCommand < Subcommandable

  def self.editor
    ENV['EDITOR'] || 'vim'
  end

  register_subcommand(:edit) {
    files = args.flat_map{|arg| PathEnv.search(arg) }

    system(editor, *files)
  }

  register_subcommand(:fix) {
    unless Object.const_defined?(:FixSubcommand)
      found = PathEnv.find('new_h-fix')
      load found.first
    end

    if Object.const_defined?(:FixSubcommand)
      FixSubcommand.run(args)
      exit 0
    end

    raise Exception, 'Unable to load FixSubcommand'
  }

end

MainCommand.run

