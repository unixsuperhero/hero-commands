
# Hero Commands

- tip subcommand
  - later:
    - tags
- h todo (`src/subcommands/h-todo.erb`)
  - 
- add generic helpers like a google subcommand: `h google ruby hash fetch method`
- maybe add `@` modifiers
  - instead of chaining subcommands, maybe accept specific options that begin
    with `@` at the end of the args list...they can be used to support this
    workflow:
    1. run a command to make sure you get the desired output, say, for example:
       a list of files
    2. press up (or ctrl-p) to show the previous cmd in the command-line...and
       then just add like `@vim` to run the same command, but this time, instead
       of displaying the list of files, open them in vim
  - maybe the list of modifiers should be a finite...very-specific list
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

