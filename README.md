
# Hero Command and Subcommands

Create a namespace for all the scripts I write.  The scripts include a wide
variety of helpers.  Helpers for git, ripping media from sites, development,
note-taking, etc.


## To do

* rewrite the erb -> bin/ build and include script that I used to have
* work on moving h-rip and other subcommands back into the bin/subcommands/ dir

## About

The DSL that Subcommandable creates handles commands with the following
properties:

* has subcommands
* has a separate task if no subcommands are given
* accepts a "dynamic" subcommand, for example...a Heroku App's name:
  * `h heroku production-app restart`

