
# Hero Commands

- add an `h tmux overview` subcommand to `h-tmux`, it will print out lots of
  detailed info like:
  - list of sessions
    - windows in each session
      - panes in each window
  - list of buffers
- add an `h-dot` subcommand for managing dotfiles.
  - add/register new dotfiles (stored in a key/value yaml file like projects)
  - edit a dotfile
  - source a dotfile (copy the source command to the clipboard and tell the user
    how/where to paste the cmd to perform the source)
- add groups as a keyword arg to `register_subcommand`
- separate the code that initiates the command processing from the code/files
  that contain the ShellCommandable classes.  in other words,
  - have a file that loads all the libs
  - loads the subcommand classes as needed
  - and only runs MainCommand.run if no other command is set to run
    - if another command is set to run...skip MainCommand altogether.
- add a `register_gateway` DSL to skip arg processing, etc.  just shift off the
  subcommand and pass the remaining args.
- implement GetoptLong-clone without raising exceptions
- move everything from `Dir.home` into a shared subdirectory
- identify all the constants (lib/(s)) used by every file, and make sure to
  `inject` them.
- change the substitutes with the branch list.  for links, we want to keep the
  left side
- **managing args and modifiers**
  - the managing of args and modifiers should probably be handled outside the
    context of specific commands/subcommands/blocks
  - keep track of the process tree...
    - which class handled the first set of args
    - which block/class handled the subcommand of the first class
    - which block/class handled the subcommand for the last subcommand
    - etc.
- maybe add `@` modifiers
  - see: **managing args and modifiers**
  - instead of chaining subcommands, maybe accept specific options that begin
    with `@` at the end of the args list...they can be used to support this
    workflow:
    1. run a command to make sure you get the desired output, say, for example:
       a list of files
    2. press up (or ctrl-p) to show the previous cmd in the command-line...and
       then just add like `@vim` to run the same command, but this time, instead
       of displaying the list of files, open them in vim
  - maybe the list of modifiers should be a finite...very-specific list
- tip subcommand
  - later:
    - tags
- h tip (`src/subcommands/h-tip.erb`)
  - use small padded numbers as IDs for tips like 001, 002...when a new
    placevalue is added because the number of tips, just rename all the files
    using the new padding and rebuild the tips dir
- add generic helpers like a google subcommand: `h google ruby hash fetch method`
- Value (`src/lib/value.rb.erb`)
  - Value class can delete keys/methods
    - either have the class overload the method to just return nil
    - or find the proper way to undef a method (i think it is undef)
  - Value class, `method_missing` tries to pass the method onto `@to_h` if it
    `respond_to?` the missing method
- ShellCommandable (`src/lib/shell_commandable.rb.erb`)
  - add options hash to `::register_subcommand`
    - accept an :abbreviation key which will let the subcommand be matched against
      even if that abbreviation isn't uniq in terms of partial subcommand names
      - this really involves updating NameMatcher#initialize to take a second
        arg which is the map of { full_name: 'abbreviation' }
      - LOL...or, you can just add the abbreviation to the list of subcommands
        when calling `register_subcommand(:full_name, :ABBREVIATION_GOES_HERE){}`
        it just won't look as pretty when listing subcommands:
        `stat[us] (st)`
- start considering ways and when to start telling people about this project
  - before advertising, there are a few things that should probably happen:
    - make a nice readme
    - remove poorly thought-out subcommands/files
    - handle command-line options better (or just handle them...`~_~'`)
    - move everything out of the home directory and into like `$HOME/h/` or
      `$HOME/hero/`
      - add a `~/.hrc` or `~/.herorc` that lets the user customize the root dir

- test:
  - make a class that extends from Value and see if the children it makes will
    have access to the instance and/or class methods defined in it.
    - would be good for like a Project class that has a #dir method

