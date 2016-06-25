
# Hero Commands

- tip subcommand
  - later:
    - tags
- add options hash to `::register_subcommand`
  - accept an :abbreviation key which will let the subcommand be matched against
    even if that abbreviation isn't uniq in terms of partial subcommand names
- start considering ways and when to start telling people about this project
  - before advertising, there are a few things that should probably happen:
    - make a nice readme
    - remove poorly thought-out subcommands/files
    - move everything out of the home directory and into like `$HOME/h/` or
      `$HOME/hero/`
      - add a `~/.hrc` or `~/.herorc` that lets the user customize the root dir

- test:
  - make a class that extends from Value and see if the children it makes will
    have access to the instance and/or class methods defined in it.
    - would be good for like a Project class that has a #dir method

