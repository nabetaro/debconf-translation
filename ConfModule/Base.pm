#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::ConfModule::Base - base ConfModule

=cut

=head1 DESCRIPTION

This is a configuration module communication package for the Debian
configuration management system. It can launch a configuration module
script (hereafter called a "confmodule") and communicate with it. Each
instance of a ConfModule is connected to a separate, running confmodule.

There are a number of stub methods that are called in response to commands
from the client. Each has the same name as the command, with "command_"
prepended, and is fed in the parameters given after the command (split on
whitespace), and whatever it returns is passed back to the configuration
module. Each of them are described below.

=cut

=head1 METHODS

=cut

package Debian::DebConf::ConfModule::Base;
use strict;
use IPC::Open2;
use FileHandle;
use Debian::DebConf::ConfigDb;
use POSIX ":sys_wait_h";
use vars qw($AUTOLOAD);

=head2 new

Create a new ConfModule. You must specify a FrontEnd
object that this COnfModule can use. If you specify a
confmodule script to run and communicate with then that
script will automatically be started and used (if not,
you can later set the read_handle, write_handle, and pid
properties of the ConfModule by hand).

=cut

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

=head2 communicate

Read one command from the confmodule, process it, and respon
to it. Returns true unless there were no more commands to read.
This is typically called in a loop. It in turn calls various
command_* methods.

=cut
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

=head2 command_input

Creates an Element to stand for the question that is to be asked and adds it to
the list of elements in our associated FrontEnd.

=cut

sub command_input {
	my $this=shift;
	my $priority=shift;
	my $question_name=shift;

	my $question=Debian::DebConf::ConfigDb::getquestion($question_name) ||
		die "$question_name doesn't exist";

	$this->frontend->add($question, $priority);
	return;
}

=head2 command_version

Compares protocol versions with the confmodule. The version property of the ConfModule
is sent to the client.

=cut

sub command_version {
	my $this=shift;
	my $version=shift;
	die "Version too low ($version)" if $version < 1;
	return $this->version;
}

=head2 command_capb

Sets the client_capb property of the ConfModule to the confmodule's capb string, and
also sets the capb_backup property of the ConfModule's assosicated FrontEnd if the
confmodule can backup. Sends the capb property of the ConfModule to the confmodule.

=cut

sub command_capb {
	my $this=shift;
	$this->client_capb([@_]);
	# Set capb_backup on the frontend if the client can backup.
	$this->frontend->capb_backup(1) if grep { $_ eq 'backup' } @_;
	return $this->capb;
}

=head2 title

Stores the specified title in the associated FrontEnd's title property.

=cut

sub command_title {
	my $this=shift;
	$this->frontend->title(join ' ', @_);

	return;
}

=head2 beginblock, endblock

These are just stubs to be overridden by other modules.

=cut

sub command_beginblock {}
sub command_endblock {}

=head2 command_go

Tells the associated FrontEnd to display items to the user, by calling its go method.
Returns whatever the FrontEnd returns.

=cut

sub command_go {
	my $this=shift;
	$this->frontend->go;
}

=head2 command_get

This must be passed a question name. It queries the question for the value set in it and
returns that to the confmodule

=cut

sub command_get {
	my $this=shift;
	my $question_name=shift;
	my $question=Debian::DebConf::ConfigDb::getquestion($question_name) ||
		die "$question_name doesn't exist";
	return $question->value if defined $question->value;
	return $question->template->default || '';
}

=head2 command_set

This must be passed a question name and a value. It sets the question's value.

=cut

sub command_set {
	my $this=shift;
	my $question_name=shift;
	my $value=shift;

	my $question=Debian::DebConf::ConfigDb::getquestion($question_name) ||
		die "$question_name doesn't exist";
	$question->value($value);
}

=head2 command_subst

This must be passed a question name, a key, and a value. It sets up variable substitutions
on the question's description so all instances of the key (wrapped in "${}") are replaced
with the value.

=cut

sub command_subst {
	my $this = shift;
	my $question_name = shift;
	my $variable = shift;
	my $value = join ' ', @_;
	
	my $question=Debian::DebConf::ConfigDb::getquestion($question_name) ||
		die "$question_name doesn't exist";
	$question->variables($variable,$value);
}

=head2 command_register

This should be passed a template name and a question name. It creates a mapping from the
question to the template.

=cut

sub command_register {
	my $this=shift;
	my $template=shift;
	my $location=shift;
	
	Debian::DebConf::ConfigDb::addmapping($template, $location);
}

=head2 command_unregister

Pass this a question name, and it will remove the mapping that creates that question, and
remove the question itself.

=cut

sub command_unregister {
	my $this=shift;
	my $location=shift;
	
	Debian::DebConf::ConfigDb::removemapping($location);
}

=head2 command_fget

Pass this a question name and a flag name. It returns the value of the specified flag on
the question. Note that internally, any properties of a Question that start with "flag_"
are flags.

=cut

sub command_fget {
	my $this=shift;
	my $question_name=shift;
	my $flag="flag_".shift;
	
	my $question=Debian::DebConf::ConfigDb::getquestion($question_name) ||
		die "$question_name doesn't exist";
	return $question->$flag();
}

=head2 command_fset

Pass this a question name, a flag name, and a value. It sets the value of the specified
flag in the specified question.

=cut

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

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
