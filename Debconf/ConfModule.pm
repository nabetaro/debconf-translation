#!/usr/bin/perl -w

=head1 NAME

Debconf::ConfModule - communicates with a ConfModule

=cut

package Debconf::ConfModule;
use strict;
use IPC::Open2;
use FileHandle;
use Debconf::Gettext;
use Debconf::Config qw(showold);
use Debconf::ConfigDb qw(getquestion addquestion disownquestion
				 disownall);
use Debconf::Priority qw(priority_valid high_enough);
use Debconf::FrontEnd::Noninteractive;
use Debconf::Log ':all';
use vars qw($AUTOLOAD);
use base qw(Debconf::Base);

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

=head1 FIELDS

=over 4

=item frontend

The frontend object that is used to interact with the user.

=item version

The protocol version spoken.

=item pid

The PID of the confmodule that is running and talking to this object, if
any.

=item write_handle

Writes to this handle are sent to the confmodule.

=item read_handle

Reads from this handle read from the confmodule.

=item caught_sigpipe

Set if we have caught a SIGPIPE signal. If it is set, the value of the
field should be returned, rather than the normal exit code.

=item client_capb

An array reference. If set, it will hold the capabilities the confmodule
reports.

=back

=head1 METHODS

=over 4

=cut

# Here I define all the numeric result codes that are used.
my %codes = (
	success => 0,
	badparams => 10,
	syntaxerror => 20,
	input_invisible => 30,
	version_bad => 30,
	go_back => 30,
	internalerror => 100,
);

=item init

Called when a ConfModule is created.

=cut

sub init {
	my $this=shift;

	# Protcol version.
	$this->version("2.0");
	
	# If my frontend thought the client confmodule could backup
	# (eg, because it was dealing earlier with a confmodule that could),
	# tell it otherwise.
	$this->frontend->capb_backup('');

	# Let clients know a FrontEnd is actually running.
	$ENV{DEBIAN_HAS_FRONTEND}=1;
}

=item startup

Pass this name name of a confmodule program, and it is started up. Any
further options are parameters to pass to the confmodule. You generally need
to do this before trying to use any of the rest of this object. The
alternative is to launch a confmodule manually, and connect the read_handle
and write_handle fields of this object to it.

=cut

sub startup {
	my $this=shift;
	my $confmodule=shift;

	my @args=$this->confmodule($confmodule);
	push @args, @_ if @_;
	
	# Try to detect the uninitialized value bug. Seems very hard to
	# reproduce, so I am going to rather excessive lenghts here.
	my $bad='';
	map { $bad=1 if ! defined $_ } @args;
	if ($bad) {
		use Carp;
		Carp::cluck(gettext("debconf: Undefined values detected at confmodule startup! Please file a bug report, and include the stack trace below"));
	}
	
	debug developer => "starting ".join(' ',@args);
	$this->pid(open2($this->read_handle(FileHandle->new),
		         $this->write_handle(FileHandle->new),
			 @args)) || die $!;
	
	
	# Catch sigpipes so they don't kill us, and return 128 for them.
	$this->caught_sigpipe('');
	$SIG{PIPE}=sub { $this->caught_sigpipe(128) };
}

=item communicate

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
	my $ret=$this->process_command($_);
	my $w=$this->write_handle;
	print $w $ret."\n";
	return '' unless length $ret;
	return 1;
}

=item process_command

Pass in a raw command, and it will be processed and handled.

=cut

sub process_command {
	my $this=shift;
	
	debug developer => "<-- $_";
	return 1 unless defined && ! /^\s*#/; # Skip blank lines, comments.
	chomp;
	my ($command, @params)=split(' ', $_);
	# Make sure $command is a valid perl function name so the autoloader
	# will catch it if nothing else.
	$command=~s/[^a-zA-Z0-9_]/_/g;
	if (lc($command) eq "stop") {
		return $this->_finish;
	}
	$command="command_".lc($command);
	my $ret=join(' ', $this->$command(@params));
	debug developer => "--> $ret";
	return $ret;
}

=item _finish

This is an internal helper function for process_command. It just waits for the
child process to finish so its return code can be examined. The return code
is stored in the exitcode field of the object.

=cut

sub _finish {
	my $this=shift;

	waitpid $this->pid, 0;
	$this->exitcode($this->caught_sigpipe || ($? >> 8));
	return '';
}

=item command_input

Creates an Element to stand for the question that is to be asked and adds it to
the list of elements in our associated FrontEnd.

=cut

sub command_input {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 2;
	my $priority=shift;
	my $question_name=shift;
	
	my $question=getquestion($question_name) ||
		return $codes{badparams}, "\"$question_name\" doesn't exist";

	if (! priority_valid($priority)) {
		return $codes{syntaxerror}, "\"$priority\" is not a valid priority";
	}

	# Figure out if the question should be displayed to the user or
	# not.
	my $visible=1;

	# Noninteractive frontends never show anything.
	$visible='' if ! $this->frontend->interactive;

	# Don't show items that are unimportant.
	$visible='' unless high_enough($priority);

	# Unless showold is set, don't re-show already seen questions. 
	$visible='' if showold() eq 'false' &&
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
		$element=Debconf::FrontEnd::Noninteractive->makeelement($question, 1);

		# If that failed, the question is just not visible.
		return $codes{input_invisible}, 'question skipped' unless $element;
	}

	$this->frontend->add($element);
	if ($element->visible) {
		return $codes{success}, "question will be asked";
	}
	else {
		return $codes{input_invisible}, "question skipped";
	}
}

=item command_clear

Clears out the list of elements in our accociated FrontEnd.

=cut

sub command_clear {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 0;

	$this->frontend->clear;
	return $codes{success};
}

=item command_version

Compares protocol versions with the confmodule. The version field of the
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

=item command_capb

Sets the client_capb field to the confmodules capb string, and also
sets the capb_backup field of the ConfModules associated FrontEnd if
the confmodule can backup. Sends the capb field of the associated
FrontEnd to the confmodule.

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

=item command_title

Stores the specified title in the associated FrontEnds title field.

=cut

sub command_title {
	my $this=shift;
	$this->frontend->title(join ' ', @_);

	return $codes{success};
}

=item beginblock, endblock

These are just stubs to be overridden by other modules.

=cut

sub command_beginblock {
	return $codes{success};
}
sub command_endblock {
	return $codes{success};
}

=item command_go

Tells the associated FrontEnd to display items to the user, by calling
its go method. Returns whatever the FrontEnd returns.

=cut

sub command_go {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ > 0;
	return $codes{go_back}, "backup" unless $this->frontend->go;
	return $codes{success}, "ok";
}

=item command_get

This must be passed a question name. It queries the question for the value
set in it and returns that to the confmodule

=cut

sub command_get {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 1;
	my $question_name=shift;
	my $question=getquestion($question_name) ||
		return $codes{badparams}, "$question_name doesn't exist";

	if (defined $question->value) {
		return $codes{success}, $question->value;
	}
	else {
		return $codes{success}, '';
	}
}

=item command_set

This must be passed a question name and a value. It sets the question's value.

=cut

sub command_set {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ < 1;
	my $question_name=shift;
	my $value=join(" ", @_);

	my $question=getquestion($question_name) ||
		return $codes{badparams}, "$question_name doesn't exist";
	$question->value($value);
	return $codes{success}, "value set";
}

=item command_reset

Reset a question to its default value.

=cut

sub command_reset {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 1;
	my $question_name=shift;

	my $question=getquestion($question_name) ||
		return $codes{badparams}, "$question_name doesn't exist";
	$question->value($question->default);
	$question->flag_isdefault('true');
	return $codes{success};
}

=item command_subst

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
	
	my $question=getquestion($question_name) ||
		return $codes{badparams}, "$question_name doesn't exist";
	$question->variables($variable,$value);
	return $codes{success};
}

=item command_register

This should be passed a template name and a question name. It creates a
question that uses the template.

=cut

sub command_register {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 2;
	my $template=shift;
	my $name=shift;
	
	addquestion($template, $name, $this->owner);
	return $codes{success};
}

=item command_unregister

Pass this a question name, and it will give up ownership of the question,
which typically causes it to be removed.

=cut

sub command_unregister {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 1;
	my $name=shift;
	
	disownquestion($name, $this->owner);
	return $codes{success};
}

=item command_purge

This will give up ownership of all questions.

=cut

sub command_purge {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ > 0;
	
	disownall($this->owner);
	return $codes{success};
}

=item command_metaget

Pass this a question name and a field name. It returns the value of the
specified field of the question.

=cut

sub command_metaget {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 2;
	my $question_name=shift;
	my $field=shift;
	
	my $question=getquestion($question_name) ||
		return $codes{badparams}, "$question_name doesn't exist";
	my $fieldval=$question->$field();
	unless (defined $fieldval) {
		return $codes{badparams}, "$field does not exist";
	}
	return $codes{success}, $fieldval;
}

=item command_fget

Pass this a question name and a flag name. It returns the value of the
specified flag on the question. Note that internally, any fields of
a Question that start with "flag_" are flags.

=cut

sub command_fget {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 2;
	my $question_name=shift;
	my $flag="flag_".shift;
	
	my $question=getquestion($question_name) ||
		return $codes{badparams},  "$question_name doesn't exist";
	return $codes{success}, $question->$flag();
}

=item command_fset

Pass this a question name, a flag name, and a value. It sets the value of
the specified flag in the specified question.

=cut

sub command_fset {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ < 2;
	my $question_name=shift;
	my $flag="flag_".shift;
	my $value=(join ' ', @_);
	
	my $question=getquestion($question_name) ||
		return $codes{badparams}, "$question_name doesn't exist";
	return $codes{success}, $question->$flag($value);
}

=item command_visible

Deprecated.

=cut

sub command_visible {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 2;
	my $priority=shift;
	my $question_name=shift;
	
	my $question=getquestion($question_name) ||
		return $codes{badparams}, "$question_name doesn't exist";
	return $codes{success}, $this->frontend->visible($question, $priority) ? "true" : "false";
}

=item command_exist

Deprecated.

=cut

sub command_exist {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 1;
	my $question_name=shift;
	
	return $codes{success}, 
		getquestion($question_name) ? "true" : "false";
}

=item AUTOLOAD

Catches all other commands the confmodule may try to run, and returns
errors.

Also handles storing and loading fields of course.

=cut

sub AUTOLOAD {
	my $field;
	($field = $AUTOLOAD) =~ s/.*://;

	if ($field=~/^command_(.*)/) {
		return $codes{syntaxerror},
		       "Unsupported command \"$1\" received from confmodule.";
	}
	else {
		no strict 'refs';
		*$AUTOLOAD = sub {
			my $this=shift;
			
			$this->{$field}=shift if @_;
			return $this->{$field};
		};
		goto &$AUTOLOAD;
	}
}

=item DESTROY

When the object is destroyed, the filehandles are closed and the confmodule
script stopped.

=cut

sub DESTROY {
	my $this=shift;
	
	$this->read_handle->close if $this->read_handle;
	$this->write_handle->close if $this->write_handle;
	if (defined $this->pid && $this->pid > 1) {
		kill 'TERM', $this->pid;
	}
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
