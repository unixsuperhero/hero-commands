#!/bin/bash

run_cmds_in="$TMUX_PANE"
tmux splitw -d -b -h -l 58 -t "$run_cmds_in"
tmux swapp -s $run_cmds_in -t -

run_cmds_in="-"

clear

cat <<T

this is a demo of command modifiers for the
hero command suite.

modifiers are special arguments that begin
with '@' and can be added to the end (or in some
cases, the middle) of a command...to change
the way it behaves

have you ever ran a command to see a list of files
that you want to edit?  and then you have to type
up or ctrl-p to see that command, and the move the
cursor around to pass those files as arguments to vim?

this should make that a lot easier...

the modifiers are:

  @vim, @capture, @each, @all

T

sleep 5
clear

cat <<T

before showing you my version of commands,
i want to show you the original versions


$> git status -s

T

sleep 5

tmux send-keys -t ":.0" 'git status -s
'

sleep 5

tmux send-keys -t ":.0" 'clear
'
clear

cat <<T

stripping out the status flags so only filenames
are left...

$> git status -s | sed 's/^...//'

T

sleep 5

tmux send-keys -t ":.0" "git status -s | sed 's/^...//'
"

sleep 5
tmux send-keys -t ":.0" 'clear
'
clear

cat <<T

my version...

$> h git status

T

tmux send-keys -t ":.0" 'h git status
'

sleep 5
tmux send-keys -t ":.0" 'clear
'
clear

cat <<T

# ...then with filtering...

$> h git status hi bye

T

tmux send-keys -t ":.0" 'h git status hi bye
'

sleep 5
tmux send-keys -t ":.0" 'clear
'
clear

cat <<T

# ...then stripping the status flags...

$> h git sfiles hi bye

T

tmux send-keys -t ":.0" 'h git sfiles hi bye
'

sleep 5
tmux send-keys -t ":.0" 'clear
'
clear

cat <<T

@capture

capture the command output, and open it in vim...
this is exactly like piping it to vim:

# modifier version:
$> h git sfiles hi bye @capture

# normal version:
$> h git sfiles hi bye | vim -

T

sleep 5

tmux send-keys -t ":.0" 'h git sfiles hi bye @capture
'

sleep 5
tmux send-keys -t ":.0" 'clear
'
clear

cat <<"T"

@vim

open each of the lines output
in vim...

$> h git sfiles hi bye @vim

# the same as...

$> vim $(h git sfiles hi bye)

T

sleep 5

tmux send-keys -t ":.0" 'h git sfiles hi bye @vim
'

sleep 5
clear

cat <<T

@each

pass each line of output as an arg to the custom command

$> h git sfiles hi bye @each cat -n

# runs:
cat -n hi
cat -n bye

T

sleep 5

tmux send-keys -t ":.0" 'h git sfiles hi bye @each cat -n
'

sleep 5
tmux send-keys -t ":.0" 'clear
'
clear

cat <<T

using '%s' as a placeholder for where
to inject the output

$> h git sfiles hi bye @each echo "prefix.%s.suffix"

runs:
echo "prefix.hi.suffix"
echo "prefix.bye.suffix"

T

sleep 5

tmux send-keys -t ":.0" 'h git sfiles hi bye @each echo "prefix.%s.suffix"
'

sleep 5
tmux send-keys -t ":.0" 'clear
'
clear

cat <<T

@all

same as @each, but only run the command 1x,
and pass all the lines as different arguments

T

sleep 5

tmux send-keys -t ":.0" 'h git sfiles hi bye @all cat -n
'

sleep 5
tmux send-keys -t ":.0" 'clear
'
clear

cat <<T

with placeholder

T

sleep 5

tmux send-keys -t ":.0" 'h git sfiles hi bye @all wc -l '%s' command_modifiers_script.md
'

sleep 5
tmux send-keys -t ":.0" 'clear
'
clear

