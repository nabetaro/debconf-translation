#!/bin/sh
# This is a shell library to interface to the Debian configration management
# system.

###############################################################################
# Initialization.

# Check to see if a FrontEnd is running.
if [ ! "$DEBIAN_HAS_FRONTEND" ]; then
	# Ok, this is pretty crazy. Since there is no FrontEnd, this
	# program execs a FrontEnd. It will then run a new copy of $0 that
	# can talk to it.
	exec /usr/share/debconf/frontend $0 $*
fi

# Only do this once.
if [ -z "$DEBCONF_REDIR" ]; then
	# Redirect standard output to standard error. This prevents common
	# mistakes by making all the output of the postinst or whatever
	# script is using this library not be parsed as confmodule commands.
	#
	# To actually send something to standard output, send it to fd 3.
	exec 3>&1 1>&2
	DEBCONF_REDIR=1
	export DEBCONF_REDIR
fi

###############################################################################
# Commands.

# Generate subroutines for all commands that don't have special handlers.
# Each command must be listed twice, once in lower case, once in upper.
# Doing that saves us a lot of calls to tr at load time. I just wish shell had
# an upper-case function.
old_opts="$@"
for i in "capb CAPB" "stop STOP" "set SET" "reset RESET" "title TITLE" \
         "input INPUT" "beginblock BEGINBLOCK" "endblock ENDBLOCK" "go GO" \
	 "get GET" "register REGISTER" "unregister UNREGISTER" "subst SUBST" \
	 "previous_module PREVIOUS_MODULE" "fset FSET" "fget FGET" \
	 "purge PURGE" "metaget METAGET"; do
	# Break string up into words.
	set -- $i
	# Generate function on the fly.
	eval "db_$1 () {
		echo \"$2 \$@\" >&3
		read _RET
		old_opts="\$@"
		set -- \$_RET
		_RET=\$1
		shift
		RET="\$*"
		set -- \$old_opts
		unset old_opts
		return \$_RET
	      }"
done
# $@ was clobbered above, unclobber.
set -- $old_opts
unset old_opts

# By default, the current protocol version is sent to the frontend. You can
# pass in a different version to override this.
db_version () {
	if [ "$1" ]; then
		echo "VERSION $1" >&3
	else
		echo "VERSION 2.0" >&3
	fi
	read _RET
	RET=`expr "$_RET" : '[0-9]* \(.*\)'` || RET=''
	_RET=`expr "$_RET" : '\([0-9]*\) .*'` || true
	return $_RET
}

# Just an alias for input. It tends to make more sense to use this to display
# text, since displaying text isn't really asking for input.
db_text () {
	db_input $@
}
