#!/usr/bin/perl -w
#
# Configuration module communication package for the Debian configuration
# management system. it can launch a configuration module script and
# communicate with it. Each instance of a ConfModule is connected to a
# separate, running configuration module.
#
# This is intended be be subclassed by each frontend. There are a number of
# stub methods that are called in response to commands from the client. Each
# has the same name as the command, and is fed in the parameters given after
# the command (split on whitespace), and whatever it returns is passed back to
# the configuration module.

package ConfModule;
use strict;
use IPC::Open2;
use FileHandle;
use vars qw($AUTOLOAD);

# Pass the filename of the configuration module to start.
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless ($self, $class);
	
	# Start up the script.
	$self->{confmodule} = shift;
	$self->{read_handle} = FileHandle->new;
	$self->{write_handle} = FileHandle->new;
	$self->{pid} = open2($self->{read_handle}, $self->{write_handle},
		             $self->{confmodule}) || die $!;
	return $self;
}

# Read one command and respond to it.
sub communicate {
	my $this=shift;
	
	my $r=$this->{read_handle};
	return if eof($r);
	$_=<$r> || die $!;
	return unless defined && ! /^\s*#/; # Skip blank lines, comments.
	chomp;
	my ($command, @params)=split(' ', $_);
	$command=lc $command;
	my $w=$this->{write_handle};
	print $w join(' ', $this->$command(@params))."\n";
	return 1;
}

sub version {
	my $this=shift;
	my $version=shift;
	die "Version too low ($version)" if $version < 1;
	return "1.0";
}

# This handles a command that is not listed above.
sub AUTOLOAD {
	my $this=shift;
	my $command = $AUTOLOAD;
	$command =~ s|.*:||; # strip fully-qualified portion
	die "Unsupported command \"$command\" received from client configuration module.";
}

# Close filehandles and stop the script.
sub DESTROY {
	my $this=shift;
	
	$this->{read_handle}->close;
	$this->{write_handle}->close;
	kill 'TERM', $this->{pid};
}

1
