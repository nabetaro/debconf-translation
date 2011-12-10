#!/usr/bin/perl -w

=head1 NAME

Debconf::ConfModule - communicates with a ConfModule

=cut

package Debconf::ConfModule;
use strict;
use IPC::Open2;
use FileHandle;
use Debconf::Gettext;
use Debconf::Config;
use Debconf::Question;
use Debconf::Priority qw(priority_valid high_enough);
use Debconf::FrontEnd::Noninteractive;
use Debconf::Log ':all';
use Debconf::Encoding;
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

=item seen

An array reference. If set, it will hold a list of all questions that have
ever been shown to the user in this confmodule run.

=item busy

An array reference. If set, it will hold a list of named of question that are
"busy" -- in the process of being shown, that cannot be unregistered right now.

=back

=head1 METHODS

=over 4

=cut

# Here I define all the numeric result codes that are used.
my %codes = (
	success => 0,
	escaped_data => 1,
	badparams => 10,
	syntaxerror => 20,
	input_invisible => 30,
	version_bad => 30,
	go_back => 30,
	progresscancel => 30,
	internalerror => 100,
);

=item init

Called when a ConfModule is created.

=cut

sub init {
	my $this=shift;

	# Protcol version.
	$this->version("2.0");
	
	$this->owner('unknown') if ! defined $this->owner;
	
	# If my frontend thought the client confmodule could backup
	# (eg, because it was dealing earlier with a confmodule that could),
	# tell it otherwise.
	$this->frontend->capb_backup('');

	$this->seen([]);
	$this->busy([]);

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

	# There is an implicit clearing of any previously pending questions
	# when a new confmodule is run.
	$this->frontend->clear;
	$this->busy([]);
	
	my @args=$this->confmodule($confmodule);
	push @args, @_ if @_;
	
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
	$_=<$r> || return $this->finish;
	chomp;
	my $ret=$this->process_command($_);
	my $w=$this->write_handle;
	print $w $ret."\n";
	return '' unless length $ret;
	return 1;
}

=item escape

Escape backslashes and newlines for output via the debconf protocol.

=cut

sub escape {
	my $text=shift;
	$text=~s/\\/\\\\/g;
	$text=~s/\n/\\n/g;
	return $text;
}

=item unescape_split

Unescape text received via the debconf protocol, and split by unescaped
whitespace.

=cut

sub unescape_split {
	my $text=shift;
	my @words;
	my $word='';
	for my $chunk (split /(\\.|\s+)/, $text) {
		if ($chunk eq '\n') {
			$word.="\n";
		} elsif ($chunk=~/^\\(.)$/) {
			$word.=$1;
		} elsif ($chunk=~/^\s+$/) {
			push @words, $word;
			$word='';
		} else {
			$word.=$chunk;
		}
	}
	push @words, $word if $word ne '';
	return @words;
}

=item process_command

Pass in a raw command, and it will be processed and handled.

=cut

sub process_command {
	my $this=shift;
	
	debug developer => "<-- $_";
	chomp;
	my ($command, @params);
	if (defined $this->client_capb and grep { $_ eq 'escape' } @{$this->client_capb}) {
		($command, @params)=unescape_split($_);
	} else {
		($command, @params)=split(' ', $_);
	}
	if (! defined $command) {
		return $codes{syntaxerror}.' '.
			"Bad line \"$_\" received from confmodule.";
	}
	$command=lc($command);
	# This command could not be handled by a sub.
	if (lc($command) eq "stop") {
		return $this->finish;
	}
	# Make sure that the command is valid.
	if (! $this->can("command_$command")) {
		return $codes{syntaxerror}.' '.
		       "Unsupported command \"$command\" (full line was \"$_\") received from confmodule.";
	}
	# Now call the subroutine for the command.
	$command="command_$command";
	my $ret=join(' ', $this->$command(@params));
	debug developer => "--> $ret";
	if ($ret=~/\n/) {
		debug developer => 'Warning: return value is multiline, and would break the debconf protocol. Truncating to first line.';
		$ret=~s/\n.*//s;
		debug developer => "--> $ret";
	}
	return $ret;
}

=item finish

Waits for the child process (if any) to finish so its return code can be
examined.  The return code is stored in the exitcode field of the object.
It also marks all questions that were shown as seen.

=cut

sub finish {
	my $this=shift;

	waitpid $this->pid, 0 if defined $this->pid;
	$this->exitcode($this->caught_sigpipe || ($? >> 8));

	# Stop catching sigpipe now. IGNORE and DEFAULT both cause obscure
	# failures, BTW.
	$SIG{PIPE} = sub {};
	
	foreach (@{$this->seen}) {
		# Try to get the question again, because it's possible it
		# was shown, and then unregistered.
		my $q=Debconf::Question->get($_->name);
		$_->flag('seen', 'true') if $q;
	}
	$this->seen([]);
	
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
	
	my $question=Debconf::Question->get($question_name) ||
		return $codes{badparams}, "\"$question_name\" doesn't exist";

	if (! priority_valid($priority)) {
		return $codes{syntaxerror}, "\"$priority\" is not a valid priority";
	}

	$question->priority($priority);
	
	# Figure out if the question should be displayed to the user or
	# not.
	my $visible=1;

	# Error questions are always shown even if they're asked at a low
	# priority or have already been seen.
	if ($question->type ne 'error') {
		# Don't show items that are unimportant.
		$visible='' unless high_enough($priority);

		# Don't re-show already seen questions, unless reconfiguring.
		$visible='' if ! Debconf::Config->reshow &&
			       $question->flag('seen') eq 'true';
	}

	# We may want to set the seen flag on noninteractive questions
	# even though they aren't shown.
	my $markseen=$visible;

	# Noninteractive frontends never show anything.
	if ($visible && ! $this->frontend->interactive) {
		$visible='';
		$markseen='' unless Debconf::Config->noninteractive_seen eq 'true';
	}

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
		return $codes{input_invisible}, "question skipped" unless $element;
	}

	$element->markseen($markseen);

	push @{$this->busy}, $question_name;
	
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
	$this->busy([]);
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

Sets the client_capb field to the confmodules's capabilities, and also
sets the capb_backup field of the ConfModules associated FrontEnd if
the confmodule can backup. Sends the capb field of the associated
FrontEnd to the confmodule.

=cut

sub command_capb {
	my $this=shift;
	$this->client_capb([@_]);
	# Set capb_backup on the frontend if the client can backup.
	if (grep { $_ eq 'backup' } @_) {
		$this->frontend->capb_backup(1);
	} else {
		$this->frontend->capb_backup('');
	}
	# Multiselect is added as a capability to fix a backwards
	# compatability problem.
	my @capb=('multiselect', 'escape');
	push @capb, $this->frontend->capb;
	return $codes{success}, @capb;
}

=item command_title

Stores the specified title in the associated FrontEnds title field.

=cut

sub command_title {
	my $this=shift;
	$this->frontend->title(join ' ', @_);
	$this->frontend->requested_title($this->frontend->title);

	return $codes{success};
}

=item command_settitle

Uses the short description of a question as the title, with automatic i18n.

=cut

sub command_settitle {
	my $this=shift;
	
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 1;
	my $question_name=shift;
	
	my $question=Debconf::Question->get($question_name) ||
		return $codes{badparams}, "\"$question_name\" doesn't exist";

	if ($this->frontend->can('settitle')) {
		$this->frontend->settitle($question);
	} else {
		$this->frontend->title($question->description);
	}
	$this->frontend->requested_title($this->frontend->title);
	
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
its go method. That method should return false if the user asked to back
up, and true otherwise. If it returns true, then all of the questions that
were displayed are added to the seen array.

=cut

sub command_go {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ > 0;

	my $ret=$this->frontend->go;
	# If no elements were shown, and we backed up last time, back up again
	# even if the user didn't indicate they want to back up. This
	# causes invisible elements to be skipped over in multi-stage backups.
	if ($ret && (! $this->backed_up ||
	             grep { $_->visible } @{$this->frontend->elements})) {
		foreach (@{$this->frontend->elements}) {
			$_->question->value($_->value);
			push @{$this->seen}, $_->question if $_->markseen && $_->question;
		}
		$this->frontend->clear;
		$this->busy([]);
		$this->backed_up('');
		return $codes{success}, "ok"
	}
	else {
		$this->frontend->clear;
		$this->busy([]);
		$this->backed_up(1);
		return $codes{go_back}, "backup";
	}
}

=item command_get

This must be passed a question name. It queries the question for the value
set in it and returns that to the confmodule

=cut

sub command_get {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 1;
	my $question_name=shift;
	my $question=Debconf::Question->get($question_name) ||
		return $codes{badparams}, "$question_name doesn't exist";

	my $value=$question->value;
	if (defined $value) {
		if (defined $this->client_capb and grep { $_ eq 'escape' } @{$this->client_capb}) {
			return $codes{escaped_data}, escape($value);
		} else {
			return $codes{success}, $value;
		}
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

	my $question=Debconf::Question->get($question_name) ||
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

	my $question=Debconf::Question->get($question_name) ||
		return $codes{badparams}, "$question_name doesn't exist";
	$question->value($question->default);
	$question->flag('seen', 'false');
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
	
	my $question=Debconf::Question->get($question_name) ||
		return $codes{badparams}, "$question_name doesn't exist";
	my $result=$question->variable($variable,$value);
	return $codes{internalerror}, "Substitution failed" unless defined $result;
	return $codes{success};
}

=item command_register

This should be passed a template name and a question name. Registers a
question to use the template.

=cut

sub command_register {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 2;
	my $template=shift;
	my $name=shift;
	
	my $tempobj = Debconf::Question->get($template);
	if (! $tempobj) {
		return $codes{badparams}, "No such template, \"$template\"";
	}
	my $question=Debconf::Question->get($name) || 
	             Debconf::Question->new($name, $this->owner, $tempobj->type);
	if (! $question) {
		return $codes{internalerror}, "Internal error making question";
	}
	if (! defined $question->addowner($this->owner, $tempobj->type)) {
		return $codes{internalerror}, "Internal error adding owner";
	}
	if (! $question->template($template)) {
		return $codes{internalerror}, "Internal error setting template";
	}

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
	
	my $question=Debconf::Question->get($name) ||
		return $codes{badparams}, "$name doesn't exist";
	if (grep { $_ eq $name } @{$this->busy}) {
		return $codes{badparams}, "$name is busy, cannot unregister right now";
	}
	$question->removeowner($this->owner);
	return $codes{success};
}

=item command_purge

This will give up ownership of all questions a confmodule owns.

=cut

sub command_purge {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ > 0;
	
	my $iterator=Debconf::Question->iterator;
	while (my $q=$iterator->iterate) {
		$q->removeowner($this->owner);
	}

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
	
	my $question=Debconf::Question->get($question_name) ||
		return $codes{badparams}, "$question_name doesn't exist";
	my $lcfield=lc $field;
	my $fieldval=$question->$lcfield();
	unless (defined $fieldval) {
		return $codes{badparams}, "$field does not exist";
	}
	if (defined $this->client_capb and grep { $_ eq 'escape' } @{$this->client_capb}) {
		return $codes{escaped_data}, escape($fieldval);
	} else {
		return $codes{success}, $fieldval;
	}
}

=item command_fget

Pass this a question name and a flag name. It returns the value of the
specified flag on the question.

=cut

sub command_fget {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 2;
	my $question_name=shift;
	my $flag=shift;
	
	my $question=Debconf::Question->get($question_name) ||
		return $codes{badparams},  "$question_name doesn't exist";
		
	return $codes{success}, $question->flag($flag);
}

=item command_fset

Pass this a question name, a flag name, and a value. It sets the value of
the specified flag in the specified question.

=cut

sub command_fset {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ < 3;
	my $question_name=shift;
	my $flag=shift;
	my $value=(join ' ', @_);
	
	my $question=Debconf::Question->get($question_name) ||
		return $codes{badparams}, "$question_name doesn't exist";

	if ($flag eq 'seen') {
		# If this question we're being asked to modify is one that was
		# shown in the current session, it will be in our seen
		# cache, and changing its value here will not persist
		# after this session, because the seen property overwrites
		# the values at the end of the session. Therefore, remove
		# it from our seen cache.
		$this->seen([grep {$_ ne $question} @{$this->seen}]);
	}
		
	return $codes{success}, $question->flag($flag, $value);
}

=item command_info

Pass this a question name. It displays the given template as an out-of-band
informative message. Unlike inputting a note, this doesn't require an
acknowledgement from the user, and depending on the frontend it may not even
be displayed at all. Frontends should display the info persistently until
some other info comes along.

With no arguments, this resets the info message to a default value.

=cut

sub command_info {
	my $this=shift;

	if (@_ == 0) {
		$this->frontend->info(undef);
	} elsif (@_ == 1) {
		my $question_name=shift;

		my $question=Debconf::Question->get($question_name) ||
			return $codes{badparams}, "\"$question_name\" doesn't exist";

		$this->frontend->info($question);
	} else {
		return $codes{syntaxerror}, "Incorrect number of arguments";
	}

	return $codes{success};
}

=item command_progress

Progress bar handling. Pass this a subcommand name followed by any arguments
required by the subcommand, as follows:

=over 4

=item START

Pass this a minimum value, a maximum value, and a question name. It creates
a progress bar with the specified range and the description of the specified
question as the title.

=item SET

Pass this a value. It sets the current position of the progress bar to the
specified value.

=item STEP

Pass this an increment. It increments the current position of the progress
bar by the specified amount.

=item INFO

Pass this a template name. It displays the specified template as an
informational message in the progress bar.

=item STOP

This subcommand takes no arguments. It destroys the progress bar.

=back

Note that the frontend's progress_set, progress_step, and progress_info 
functions should return true, unless the progress bar was canceled.

=cut

sub command_progress {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ < 1;
	my $subcommand=shift;
	$subcommand=lc($subcommand);
	
	my $ret;

	if ($subcommand eq 'start') {
		return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 3;
		my $min=shift;
		my $max=shift;
		my $question_name=shift;

		return $codes{syntaxerror}, "min ($min) > max ($max)" if $min > $max;

		my $question=Debconf::Question->get($question_name) ||
			return $codes{badparams}, "$question_name doesn't exist";

		$this->frontend->progress_start($min, $max, $question);
		$ret=1;
	}
	elsif ($subcommand eq 'set') {
		return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 1;
		my $value=shift;
		$ret = $this->frontend->progress_set($value);
	}
	elsif ($subcommand eq 'step') {
		return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 1;
		my $inc=shift;
		$ret = $this->frontend->progress_step($inc);
	}
	elsif ($subcommand eq 'info') {
		return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 1;
		my $question_name=shift;

		my $question=Debconf::Question->get($question_name) ||
			return $codes{badparams}, "$question_name doesn't exist";

		$ret = $this->frontend->progress_info($question);
	}
	elsif ($subcommand eq 'stop') {
		return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 0;
		$this->frontend->progress_stop();
		$ret=1;
	}
	else {
		return $codes{syntaxerror}, "Unknown subcommand";
	}

	if ($ret) {
		return $codes{success}, "OK";
	}
	else {
		return $codes{progresscancel}, "CANCELED";
	}
}

=item command_data

Accept template data from the client, for use on the UI agent side of the
passthrough frontend.

TODO: Since process_command() collapses multiple spaces in commands into
single spaces, this doesn't quite handle bulleted lists correctly.

=cut

sub command_data {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ < 3;
	my $template=shift;
	my $item=shift;
	my $value=join(' ', @_);
	$value=~s/\\([n"\\])/($1 eq 'n') ? "\n" : $1/eg;

	my $tempobj=Debconf::Template->get($template);
	if (! $tempobj) {
		if ($item ne 'type') {
			return $codes{badparams}, "Template data field '$item' received before type field";
		}
		$tempobj=Debconf::Template->new($template, $this->owner, $value);
		if (! $tempobj) {
			return $codes{internalerror}, "Internal error making template";
		}
	} else {
		if ($item eq 'type') {
			return $codes{badparams}, "Template type already set";
		}
		$tempobj->$item(Debconf::Encoding::convert("UTF-8", $value));
	}

	return $codes{success};
}

=item command_visible

Deprecated.

=cut

sub command_visible {
	my $this=shift;
	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ != 2;
	my $priority=shift;
	my $question_name=shift;
	
	my $question=Debconf::Question->get($question_name) ||
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
		Debconf::Question->get($question_name) ? "true" : "false";
}

=item command_x_loadtemplatefile

Extension to load a specified template file.

=cut

sub command_x_loadtemplatefile {
	my $this=shift;

	return $codes{syntaxerror}, "Incorrect number of arguments" if @_ < 1 || @_ > 2;

	my $file=shift;
	my $fh=FileHandle->new($file);
	if (! $fh) {
		return $codes{badparams}, "failed to open $file: $!";
	}

	my $owner=$this->owner;
	if (@_) {
		$owner=shift;
	}

	eval {
		Debconf::Template->load($fh, $owner);
	};
	if ($@) {
		$@=~s/\n/\\n/g;
		return $codes{internalerror}, $@;
	}
	return $codes{success};
}

=item AUTOLOAD

Handles storing and loading fields.

=cut

sub AUTOLOAD {
	(my $field = our $AUTOLOAD) =~ s/.*://;

	no strict 'refs';
	*$AUTOLOAD = sub {
		my $this=shift;
		
		return $this->{$field} unless @_;
		return $this->{$field}=shift;
	};
	goto &$AUTOLOAD;
}

=item DESTROY

When the object is destroyed, the filehandles are closed and the confmodule
script stopped. All questions that have been displayed during the lifetime
of the confmodule are marked as seen.

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

Joey Hess <joeyh@debian.org>

=cut

1
