#!/usr/bin/perl -w
#
# Configuration module communication package for the Debian configuration
# management system. it can launch a configuration module script and
# communicate with it. Each instance of a ConfModule is connected to a
# separate, running configuration module.
#
# There are a number of stub methods that are called in response to commands
# from the client. Each has the same name as the command, with "command_"
# prepended, and is fed in the parameters given after the command (split on
# whitespace), and whatever it returns is passed back to the configuration
# module.

package Debian::DebConf::ConfModule::Base;
use strict;
use IPC::Open2;
use FileHandle;
use Debian::DebConf::ConfigDb;
use POSIX ":sys_wait_h";
use vars qw($AUTOLOAD);

# Pass in the FrontEnd it should use to ask questions.
# If you also pass in a filename of a confmodule to run, the confmodule
# will be started up.
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless ($self, $class);
	
	$self->{frontend} = shift;
	$self->{version} = "1.0";
	$self->{capb} = '';

	# Let clients know a FrontEnd is actually running.
	$ENV{DEBIAN_HAS_FRONTEND}=1;

	if (@_) {
		$self->{confmodule} = shift;
		$self->{read_handle} = FileHandle->new;
		$self->{write_handle} = FileHandle->new;
		$self->{pid} = open2($self->{read_handle}, 
			$self->{write_handle}, $self->{confmodule}) || die $!;
	}

	return $self;
}

# Read one command and respond to it.
sub communicate {
	my $this=shift;
	my $r=$this->{read_handle};
	$_=<$r> || return;
	chomp;
	return 1 unless defined && ! /^\s*#/; # Skip blank lines, comments.
	chomp;
	my ($command, @params)=split(' ', $_);
	return if (lc($command) eq "stop");
	$command="command_".lc($command);
	my $w=$this->{write_handle};
	print $w join(' ', $this->$command(@params))."\n";
	return 1;
}

###############################################################################
# Communication with the frontend. Each function corresponds to a command
# from the frontend.

# Add to the list of elements in our associated FrontEnd.
sub command_input {
	my $this=shift;
	my $priority=shift;
	my $question_name=shift;

	my $question=Debian::DebConf::ConfigDb::getquestion($question_name) ||
		die "$question_name doesn't exist";

	# TODO: detect bad question names, return error.
	$this->frontend->add($question, $priority);
	return;
}

sub command_version {
	my $this=shift;
	my $version=shift;
	die "Version too low ($version)" if $version < 1;
	return $this->version;
}

sub command_capb {
	my $this=shift;
	$this->client_capb([@_]);
	# Set capb_backup on the frontend if the client can backup.
	$this->frontend->capb_backup(1) if grep { $_ eq 'backup' } @_;
	return $this->capb;
}

# Just store the title.
sub command_title {
	my $this=shift;
	$this->frontend->title(join ' ', @_);

	return;
}

# Don't handle blocks.
sub command_beginblock {}
sub command_endblock {}

# Tell the frontend to display items to the user. Anything
# the frontend returns is our return value.
sub command_go {
	my $this=shift;
	$this->frontend->go;
}

# Pull a value out of a question.
sub command_get {
	my $this=shift;
	my $question_name=shift;
	my $question=Debian::DebConf::ConfigDb::getquestion($question_name) ||
		die "$question_name doesn't exist";
	return $question->value if defined $question->value;
	return $question->template->default || '';
}

# Set a value.
sub command_set {
	my $this=shift;
	my $question_name=shift;
	my $value=shift;

	my $question=Debian::DebConf::ConfigDb::getquestion($question_name) ||
		die "$question_name doesn't exist";
	$question->value($value);
}

# Set a variable
sub command_subst {
	my $this = shift;
	my $question_name = shift;
	my $variable = shift;
	my $value = join ' ', @_;
	
	my $question=Debian::DebConf::ConfigDb::getquestion($question_name) ||
		die "$question_name doesn't exist";
	$question->variables($variable,$value);
}

# Add a mapping.
sub command_register {
	my $this=shift;
	my $template=shift;
	my $location=shift;
	
	Debian::DebConf::ConfigDb::addmapping($template, $location);
}

# Remove a mapping.
sub command_unregister {
	my $this=shift;
	my $location=shift;
	
	Debian::DebConf::ConfigDb::removemapping($location);
}

# Get a flag.
sub command_fget {
	my $this=shift;
	my $question_name=shift;
	my $flag="flag_".shift;
	
	my $question=Debian::DebConf::ConfigDb::getquestion($question_name) ||
		die "$question_name doesn't exist";
	return $question->$flag();
}

# Set a flag.
sub command_fset {
	my $this=shift;
	my $question_name=shift;
	my $flag="flag_".shift;
	my $value=shift;
	
	my $question=Debian::DebConf::ConfigDb::getquestion($question_name) ||
		die "$question_name doesn't exist";
	return $question->$flag($value);
}

sub AUTOLOAD {
	my $this=shift;
	my $property = $AUTOLOAD;
	$property =~ s|.*:||; # strip fully-qualified portion
	if ($property=~/^command_(.*)/) {
		die "Unsupported command \"$1\" received from client configuration module.";
	}
	else {
		$this->{$property}=shift if @_;
		return $this->{$property};
	}
}

# Close filehandles and stop the script.
sub DESTROY {
	my $this=shift;
	
	$this->{read_handle}->close;
	$this->{write_handle}->close;
	if ($this->{pid} > 1) {
		kill 'TERM', $this->{pid};
	}
}

1
