#!/bin/sh
# This is a shell library to interface to the Debian configration management
# system.

###############################################################################
# Initialization.

# Check to see if a FrontEnd is running.
if [ ! "$DEBIAN_HAS_FRONTEND" ]; then
	# Ok, this is pretty crazy. Since there is no FrontEnd, this
	# program will turn into the FrontEnd. It will then run a new copy
	# of $0 that can talk to it.
	#
	# Yes, Sean, it's ugly, but it works. :-)
	exec perl -e '
		use strict;
		use lib ".";
		use Debian::DebConf::ConfigDb;
		use Debian::DebConf::Config;
		
		# Load up previous state information.
		if (-e $Debian::DebConf::Config::dbfn) {
			Debian::DebConf::ConfigDb::loaddb($Debian::DebConf::Config::dbfn);
		}
		
		my $type=ucfirst($ENV{DEBIAN_FRONTEND} || "base" );
		
		my $frontend=eval qq{
			use Debian::DebConf::FrontEnd::$type;
			Debian::DebConf::FrontEnd::$type->new();
	        };
		die $@ if $@;
		my $confmodule=eval qq{
			use Debian::DebConf::ConfModule::$type;
			Debian::DebConf::ConfModule::$type->new(\$frontend, join " ",\@ARGV);
		};
		die $@ if $@;
		
		# Talk to it until it is done.
		1 while ($confmodule->communicate);
		
		# Save state.
		Debian::DebConf::ConfigDb::savedb($Debian::DebConf::Config::dbfn);
	' $0 $*
fi

# Redirect standard output to standard error. This prevents common mistakes by
# making all the output of the postinst or whatever script is using this
# library not be parsed as confmodule commands.
#
# To actually send something to standard output, send it to fd 3.
exec 3>&1 1>&2

# For internal use, send text to the frontend.
_command () {
	echo $* >&3
}

###############################################################################
# Commands.

# Generate subroutines for all commands that don't have special handlers.
# Each command must be listed twice, once in lower case, once in upper.
# Doing that saves us a lot of calls to tr at load time. I just wish shell had
# an upper-case function.
old_opts="$@"
for i in "capb CAPB" "stop STOP" "reset RESET" "title TITLE" \
         "input INPUT" "beginblock BEGINBLOCK" "endblock ENDBLOCK" "go GO" \
	 "get GET" "register REGISTER" "unregister UNREGISTER" "subst SUBST" \
	 "previous_module PREVIOUS_MODULE" "fset FSET" "fget FGET"; do
	# Break string up into words.
	set -- $i
	eval "$1 () { _command \"$2 \$@\" ; read RET; }"
done
# $@ was clobbered above, unclobber.
set -- $old_opts
unset old_opts

# By default, the current protocol version is sent to the frontend. You can
# pass in a different version to override this.
version () {
	if [ "$1" ]; then
		_command "VERSION $1"
	else
		_command "VERSION 1.0"
	fi
	read RET
}

# Just an alias for input. It tends to make more sense to use this to display
# text, since displaying text isn't really asking for input.
text () {
	input $@
}
