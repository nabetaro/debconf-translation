#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::ConfModule - base ConfModule

=cut

=head1 DESCRIPTION

This is a configuration module communication package for the Debian
configuration management system. It can launch a configuration module
script (hereafter called a "confmodule") and communicate with it. Each
instance of a ConfModule is connected to a separate, running confmodule.

There are a number of methods that are called in response to commands
from the client. Each has the same name as the command, with "command_"
prepended, and is fed in the parameters given after the command (split on
whitespace), and whatever it returns is passed back to the configuration
module. Each of them are described below.

=cut

=head1 METHODS

=cut

package Debian::DebConf::ConfModule;
use strict;
use IPC::Open2;
use FileHandle;
use Debian::DebConf::ConfigDb;
use Debian::DebConf::Priority;
use Debian::DebConf::FrontEnd::Noninteractive;
use Debian::DebConf::Log ':all';
use vars qw($AUTOLOAD);
use base qw(Debian::DebConf::Base);

# Here I define all the numeric result codes that are used.
my %codes = (
	success => 0,
	badquestion => 10,
	syntaxerror => 20,
	input_invisible => 30,
	version_bad => 30,
	go_back => 30,
	internalerror => 100,
);

=head2 new

Create a new ConfModule. Pass in a FrontEnd object that this object
can use.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $this  = bless $proto->SUPER::new(@_), $class;
	
	$this->frontend(shift);
	$this->version("2.0");

	# Let clients know a FrontEnd is actually running.
	$ENV{DEBIAN_HAS_FRONTEND}=1;

	return $this;
}

=head2 startup

Pass this name name of a confmodule program, and it is started up. Any
further options are parameters to pass to the confmodule. You enerally need
to do this before trying to use any of the rest of this object. The
alternative is to launch a confmodule manually, and connect the read_handle
and write_handle properties of this object to it.

=cut

sub startup {
	my $this=shift;
	my $confmodule=shift;

	my @args=$this->confmodule($confmodule);
	push @args, @_ if @_;
	
	debug 2, "starting ".join(' ',@args);
	$this->pid(open2($this->read_handle(FileHandle->new),
		         $this->write_handle(FileHandle->new),
			 @args)) || die $!;
	
	# Catch sigpipes so they don't kill us, and return 128 for them.
	$this->caught_sigpipe('');
	$SIG{PIPE}=sub { $this->caught_sigpipe(128) };
}

=head2 communicate

Read one command from the confmodule, process it, and respond
to it. Returns true unless there were no more commands to read.
This is typically called in a loop. It in turn calls various
command_* methods.

=cut
sub communicate {
	my $this=shift;

	my $r=$this->read_handle;
	$_=<$r> || return $this->_finish;
	chomp;
	debug 1, "<-- $_";
	return 1 unless defined && ! /^\s*#/; # Skip blank lines, comments.
	chomp;
	my ($command, @params)=split(' ', $_);
	# Make sure $command is a valid perl function name so the autoloader
	# will catch it if nothing else.
	$command=~s/[^a-zA-Z0-9_]/_/g;
	my $w=$this->write_handle;
	if (lc($command) eq "stop") {
		return $this->_finish;
	}
	$command="command_".lc($command);
	my $ret=join(' ', $this->$command(@params));
	debug 1, "--> $ret";
	print $w $ret."\n";
	return 1;
}

=head2 _finish

This is an internal helper function for communicate. It just waits for the
child process to finish so its return code can be examined. The return code
is stored in the exitcode property of the object.

=cut

sub _finish {
	my $this=shift;

	waitpid $this->pid, 0;
	$this->exitcode($this->caught_sigpipe || ($? >> 8));
	return '';
}

=head2 command_input

Creates an Element to stand for the question that is to be asked and adds it to
the list of elements in our associated FrontEnd.

=cut

sub command_input {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 2;
	my $priority=shift;
	my $question_name=shift;
	
	my $question=Debian::DebConf::ConfigDb::getquestion($question_name) ||
		return $codes{badquestion}, "\"$question_name\" doesn't exist";

	if (! Debian::DebConf::Priority::valid($priority)) {
		return $codes{syntaxerror}, "\"$priority\" is not a valid priority";
	}

	# Figure out if the question should be displayed to the user or
	# not.
	my $visible=1;

	# Noninteractive frontends never show anything.
	$visible='' if ! $this->frontend->interactive;

	# Don't show items that are unimportant.
	$visible='' unless Debian::DebConf::Priority::high_enough($priority);

	# Unless showold is set, don't re-show already seen questions. 
	$visible='' if Debian::DebConf::Config::showold() eq 'false' &&
		$question->flag_isdefault eq 'false';

	my $element;
	if ($visible) {
		# Create an input Element of the type associated with
		# the frontend.
		$element=$this->frontend->makeelement($question);
		# If that failed, quit now. This should never happen.
		unless ($element) {
			return $codes{internalerror},
			       "unable to make an input element";
		}

		# Ask the Element if it thinks it is visible. If not,
		# fall back below to making a noninteractive element.
		#
		# This last check is useful, because for example, select
		# Elements are not really visible if they have less than
		# two choices.
		$visible=$element->visible;
	}

	if (! $visible) {
		# Create a noninteractive element. Supress debug messages
		# because they generate FAQ's and are harmless.
		$element=Debian::DebConf::FrontEnd::Noninteractive->makeelement($question, 1);

		# If that failed, the question is just not visible.
		return $codes{input_invisible} unless $element;
	}

	$this->frontend->add($element);
	return $element->visible ? $codes{success} : $codes{input_invisible};
}

=head2 command_clear

Clears out the list of elements in our accociated FrontEnd.

=cut

sub command_clear {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 0;

	$this->frontend->clear;
	return $codes{success};
}

=head2 command_version

Compares protocol versions with the confmodule. The version property of the
ConfModule is sent to the client.

=cut

sub command_version {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ > 1;
	my $version=shift;
	if (defined $version) {
		return $codes{version_bad}, "Version too low ($version)"
			if int($version) < int($this->version);
		return $codes{version_bad}, "Version too high ($version)"
			if int($version) > int($this->version);
	}
	return $codes{success}, $this->version;
}

=head2 command_capb

Sets the client_capb property of the ConfModule to the confmodules
capb string, and also sets the capb_backup property of the ConfModules
associated FrontEnd if the confmodule can backup. Sends the capb property
of the associated FrontEnd to the confmodule.

=cut

sub command_capb {
	my $this=shift;
	$this->client_capb([@_]);
	# Set capb_backup on the frontend if the client can backup.
	$this->frontend->capb_backup(1) if grep { $_ eq 'backup' } @_;
	# Multiselect is added as a capability to fix a backwards
	# compatability problem.
	my @capb=('multiselect');
	push @capb, $this->frontend->capb;
	return $codes{success}, @capb;
}

=head2 title

Stores the specified title in the associated FrontEnds title property.

=cut

sub command_title {
	my $this=shift;
	$this->frontend->title(join ' ', @_);

	return $codes{success};
}

=head2 beginblock, endblock

These are just stubs to be overridden by other modules.

=cut

sub command_beginblock {
	return $codes{success};
}
sub command_endblock {
	return $codes{success};
}

=head2 command_go

Tells the associated FrontEnd to display items to the user, by calling
its go method. Returns whatever the FrontEnd returns.

=cut

sub command_go {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ > 0;
	return $codes{go_back} unless $this->frontend->go;
	return $codes{success};
}

=head2 command_get

This must be passed a question name. It queries the question for the value
set in it and returns that to the confmodule

=cut

sub command_get {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 1;
	my $question_name=shift;
	my $question=Debian::DebConf::ConfigDb::getquestion($question_name) ||
		return $codes{badquestion}, "$question_name doesn't exist";

	if (defined $question->value) {
		return $codes{success}, $question->value;
	}
	else {
		return $codes{success}, '';
	}
}

=head2 command_set

This must be passed a question name and a value. It sets the question's value.

=cut

sub command_set {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ < 1;
	my $question_name=shift;
	my $value=join(" ", @_);

	my $question=Debian::DebConf::ConfigDb::getquestion($question_name) ||
		return $codes{badquestion}, "$question_name doesn't exist";
	$question->value($value);
	return $codes{success};
}

=head2 command_reset

Reset a question to its default value.

=cut

sub command_reset {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 1;
	my $question_name=shift;

	my $question=Debian::DebConf::ConfigDb::getquestion($question_name) ||
		return $codes{badquestion}, "$question_name doesn't exist";
	$question->value($question->default);
	$question->flag_isdefault('true');
	return $codes{success};
}

=head2 command_subst

This must be passed a question name, a key, and a value. It sets up variable
substitutions on the questions description so all instances of the key
(wrapped in "${}") are replaced with the value.

=cut

sub command_subst {
	my $this = shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ < 2;
	my $question_name = shift;
	my $variable = shift;
	my $value = (join ' ', @_);
	
	my $question=Debian::DebConf::ConfigDb::getquestion($question_name) ||
		return $codes{badquestion}, "$question_name doesn't exist";
	$question->variables($variable,$value);
	return $codes{success};
}

=head2 command_register

This should be passed a template name and a question name. It creates a
question that uses the template.

=cut

sub command_register {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 2;
	my $template=shift;
	my $name=shift;
	
	Debian::DebConf::ConfigDb::addquestion($template, $name, $this->owner);
	return $codes{success};
}

=head2 command_unregister

Pass this a question name, and it will give up ownership of the question,
which typically causes it to be removed.

=cut

sub command_unregister {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 1;
	my $name=shift;
	
	Debian::DebConf::ConfigDb::disownquestion($name, $this->owner);
	return $codes{success};
}

=head2 command_purge

This will give up ownership of all questions.

=cut

sub command_purge {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ > 0;
	
	Debian::DebConf::ConfigDb::disownall($this->owner);
	return $codes{success};
}

=head2 command_metaget

Pass this a question name and a field name. It returns the value of the
specified field of the question.

=cut

sub command_metaget {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 2;
	my $question_name=shift;
	my $field=shift;
	
	my $question=Debian::DebConf::ConfigDb::getquestion($question_name) ||
		return $codes{badquestion}, "$question_name doesn't exist";
	return $codes{success}, $question->$field();
}

=head2 command_fget

Pass this a question name and a flag name. It returns the value of the
specified flag on the question. Note that internally, any properties of
a Question that start with "flag_" are flags.

=cut

sub command_fget {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 2;
	my $question_name=shift;
	my $flag="flag_".shift;
	
	my $question=Debian::DebConf::ConfigDb::getquestion($question_name) ||
		return $codes{badquestion},  "$question_name doesn't exist";
	return $codes{success}, $question->$flag();
}

=head2 command_fset

Pass this a question name, a flag name, and a value. It sets the value of
the specified flag in the specified question.

=cut

sub command_fset {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ < 2;
	my $question_name=shift;
	my $flag="flag_".shift;
	my $value=(join ' ', @_);
	
	my $question=Debian::DebConf::ConfigDb::getquestion($question_name) ||
		return $codes{badquestion}, "$question_name doesn't exist";
	return $codes{success}, $question->$flag($value);
}

=head2 command_visible

Deprecated.

=cut

sub command_visible {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 2;
	my $priority=shift;
	my $question_name=shift;
	
	my $question=Debian::DebConf::ConfigDb::getquestion($question_name) ||
		return $codes{badquestion}, "$question_name doesn't exist";
	return $codes{success}, $this->frontend->visible($question, $priority) ? "true" : "false";
}

=head2 command_exist

Deprecated.

=cut

sub command_exist {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 1;
	my $question_name=shift;
	
	return $codes{success}, 
		Debian::DebConf::ConfigDb::getquestion($question_name) ? "true" : "false";
}

sub AUTOLOAD {
	my $this=shift;
	my $property = $AUTOLOAD;
	$property =~ s|.*:||; # strip fully-qualified portion
	if ($property=~/^command_(.*)/) {
		return $codes{syntaxerror},
		       "Unsupported command \"$1\" received from confmodule.";
	}
	else {
		$this->{$property}=shift if @_;
		return $this->{$property};
	}
}

=head2 DESTROY

When the object is destroyed, the filehandles are closed and the confmodule
script stopped.

=cut

sub DESTROY {
	my $this=shift;
	
	$this->read_handle->close;
	$this->write_handle->close;
	if ($this->pid > 1) {
		kill 'TERM', $this->pid;
	}
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
