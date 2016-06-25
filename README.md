
# Hero Command and Subcommands

A command-line tool with a simple/standardized way of adding new subcommands.  I
started making all of my command-line tools subcommands for Hero for a few
reasons:

1. so they are grouped together
2. so that it doesn't clutter the global namespace or name-clash with any other
   unix commands

## Making new subcommands

The ShellCommandable module adds a DSL with methods that make it _really_ easy
to add subcommands:

```
# new script that uses ShellCommandable
# file: example
#!/usr/bin/env ruby

require './lib/shell_commandable'

class MainCommand
  include ShellCommandable

  register_subcommand(:ls) {
    system('ls -l')
  }
end

MainCommand.run

# command-line
# $> example ls
```

## About

The DSL that Subcommandable creates handles commands with the following
properties:

* has subcommands
* has a separate task if no subcommands are given
* accepts a "dynamic" subcommand, for example...a Heroku App's name:
  * `h heroku production-app restart`


## To do

- for subcommands that echo a directory or something that you can not cd into
  without making new `$SHELL` processes...copy the cd command or whatever
  command directly to the clipboard, that way we can just paste and the cmd is
  already there
- `h ssh`
  - `authorize_key` - either gets it from the clipboard (pbpaste) or from a file
    the user passes in
  - `copy_key` - puts one of the existing public keys in the clipboard (pbcopy)
  - `hosts` - list hosts in ~/.ssh/config
  - `add_host` - the user specifies the alias, connection string
    `git@heroku.com:someapp.git` and then has the user select the key to use
    from a list...and it can automatically add it to `~/.ssh/config`


