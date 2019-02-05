#!/usr/bin/env bash
AWK=$(which awk)
GREP=$(which grep)
TTYBIN=$(which tty)
SSHBIN=$(which ssh)
TMUXBIN=$(which tmux)
FINDHOST="/home/dylanh/svn/Infra/trunk/scripts/findhost.pl"
# maximum number of panes tmuxsplit will open
MAXPANES=10
SSHUSER="root"

[ -z "$1" ] && (echo "I need a hostname regex or seed"; exit)
[ -z "$TMUX" ] && (echo "You're not in tmux"; exit)
mapfile -t RESULTS < <( $FINDHOST $1 )

RESULTCOUNT="${#RESULTS[@]}"
# Lets do some sanity checks on the output of findout
if [ "$RESULTCOUNT" -gt "$MAXPANES"  ]; then
	echo "Too many results! (${RESULTCOUNT}) Revise your hostname seed"
		exit 1
fi
if [ "$RESULTCOUNT" -lt 1  ]; then 
	echo "0 Results! Revise your hostname seed"
	exit 1
fi

# Sanity checks have passed, now get the first entry. We'll just ssh from this script, and allow the current pane to become the first entry. That way, if we have
# synchronisation on and we CTRL-D to quit all the shells of the remote hosts, there will be one pane left to keep the window alive. Otherwise, you end up with a "seed"
# pane, which is undesirable if you want to make the most of your screen space

# get the current tty
mytty=$(${TTYBIN})
# Then look for it in the list of tmux panes
tmuxsession=$($TMUXBIN list-panes -a -F '#{pane_tty} #{session_name}' | ${GREP} "${mytty} " | ${AWK} '{print $2}')

for (( i=1; i<${#RESULTS[@]}; i++ ));
do
	$TMUXBIN split-window -t $tmuxsession -h "ssh -l ${SSHUSER} ${RESULTS[$i]}"
done
# tile it nicely
$TMUXBIN select-layout -t $tmuxsession tiled > /dev/null
# now just ssh to the first line of the results
ssh -l ${SSHUSER} ${RESULTS[0]}
