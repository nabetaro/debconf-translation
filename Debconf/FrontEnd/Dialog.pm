#!/usr/bin/perl -w

=head1 NAME

Debconf::FrontEnd::Dialog - dialog FrontEnd

=cut

package Debconf::FrontEnd::Dialog;
use strict;
use Debconf::Gettext;
use Debconf::Priority;
use Debconf::TmpFile;
use Debconf::Log qw(:all);
use Text::Wrap qw(wrap $columns);
use Text::Tabs;
use IPC::Open3;
use base qw(Debconf::FrontEnd::ScreenSize);

=head1 DESCRIPTION

This FrontEnd is for a user interface based on dialog or whiptail.
It will use whichever is available, but prefers to use whiptail if available.
It handles all the messy communication with thse programs.

=head1 METHODS

=over 4

=item init

Checks to see if whiptail, or dialog are available, in that
order. To make it use dialog, set FORCE_DIALOG in the environment.

=cut

sub init {
	my $this=shift;

	$this->SUPER::init(@_);

	# Detect all the ways people have managed to screw up their
	# terminals (so far...)
	if (! exists $ENV{TERM} || ! defined $ENV{TERM} || $ENV{TERM} eq '') { 
		die gettext("TERM is not set, so the Dialog frontend is not usable.")."\n";
	}
	elsif ($ENV{TERM} =~ /emacs/i) {
		die gettext("Dialog frontend is incompatible with emacs shell buffers")."\n";
	}
	elsif ($ENV{TERM} eq 'dumb') {
		die gettext("Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.")."\n";
	}

	# Whiptail and dialog can't deal with very small screens. Detect
	# this and fail, forcing use of some other frontend.
	# The numbers were arrived at by experimentation.
	if ($this->screenheight < 13 || $this->screenwidth < 31) {
		die gettext("Dialog frontend requires a screen at least 13 lines tall and 31 columns wide.")."\n";
	}
	
	$this->interactive(1);
	$this->capb('backup');

	# Autodetect if whiptail or dialog is available and set magic numbers.
	if (-x "/usr/bin/whiptail" && ! defined $ENV{FORCE_DIALOG} &&
	    ! defined $ENV{FORCE_GDIALOG}) {
		$this->program('whiptail');
		$this->dashsep('--');
		$this->borderwidth(5);
		$this->borderheight(6);
		$this->spacer(1);
		$this->titlespacer(10);
		$this->columnspacer(3);
		$this->selectspacer(9);
	}
	elsif (-x "/usr/bin/dialog" && ! defined $ENV{FORCE_GDIALOG}) {
		$this->program('dialog');
		$this->dashsep(''); # dialog does not need (or support) 
		                    # double-dash separation
		$this->borderwidth(7);
		$this->borderheight(6);
		$this->spacer(0);
		$this->titlespacer(4);
		$this->columnspacer(2);
		$this->selectspacer(0);
	}
# Disabled until it supports --passwordbox and --nocancel
#	elsif (-x "/usr/bin/gdialog") {
#		$this->program}(gdialog);
#		$this->borderwidth(5);
#		$this->borderheight(6);
#		$this->spacer(1);
#		$this->titlespacer(10);
#		$this->columnspacer(0);
#	}
	else {
		die gettext("Neither whiptail nor dialog are installed, so the dialog based frontend cannot be used.");
	}

	if (Debconf::Config->sigils ne 'false') {
		# Defualt to not using smileys.
		if (Debconf::Config->smileys eq 'true') {
                        require Debconf::Sigil::Smiley;
                        $this->sigil(Debconf::Sigil::Smiley->new);
                }
                else {
                        require Debconf::Sigil::Punctuation;
                        $this->sigil(Debconf::Sigil::Punctuation->new);
                }
        }
	
}

=item sizetext

Dialog and whiptail have an annoying field of requiring you specify
their dimentions explicitly. This function handles doing that. Just pass in
the text that will be displayed in the dialog, and it will spit out new text,
formatted nicely, then the height for the dialog, and then the width for the
dialog.

=cut

sub sizetext {
	my $this=shift;
	my $text=shift;
	
	# Try to guess how many lines the text will take up in the dialog.
	# This is difficult because long lines are wrapped. So what I'll do
	# is pre-wrap the text and then just look at the number of lines it
	# takes up.
	$columns = $this->screenwidth - $this->borderwidth - $this->columnspacer;
	# Why call expand? Well, wrap gratuitously calls unexpand. However,
	# unexpand puts in tabs dialog does not deal with the way one would
	# expect. Bleagh.
#	$Text::Wrap::break=q/\s+/;
	$text=expand(wrap('', '', $text));
	my @lines=split(/\n/, $text);
	
	# Now figure out what's the longest line. Look at the title size too.
	my $window_columns=length($this->title) + $this->titlespacer;
	map { $window_columns=length if length > $window_columns } @lines;
	
	return $text, $#lines + 1 + $this->borderheight,
	       $window_columns + $this->borderwidth;
}

=item showtext

Pass this some text and it will display the text to the user in
a dialog. If the text is too long to fit in one dialog, it will use a
scrollable dialog.

=cut

sub showtext {
	my $this=shift;
	my $question=shift;
	my $intext=shift;

	my $lines = $this->screenheight;
	my ($text, $height, $width)=$this->sizetext($intext);

	my @lines = split(/\n/, $text);
	my $num;
	my @args=('--msgbox', join("\n", @lines));
	if ($lines - 4 - $this->borderheight <= $#lines) {
		$num=$lines - 4 - $this->borderheight;
		if ($this->program eq 'whiptail') {
			# Whiptail can scroll text easily.
			push @args, '--scrolltext';
		}
		else {
			# Dialog has to use a temp file.
			my $fh=Debconf::TmpFile::open();
			print $fh join("\n", @lines);
			close $fh;
			@args=("--textbox", Debconf::TmpFile::filename());
		}
	}
	else {
		$num=$#lines + 1;
	}
	$this->showdialog($question, @args, $num + $this->borderheight, $width);
	if ($args[0] eq '--textbox') {
		Debconf::TmpFile::cleanup();
	}
}

=item makeprompt

This is a helper function used by some dialog Elements. Pass it the Question
that is going to be displayed. It will use this to generate a prompt, using
both the short and long descriptions of the Question.

You can optionally pass in a second parameter: a number. This can be used to
tune how many lines are free on the screen.

If the prompt is too large to fit on the screen, it will instead be displayed
immediatly, and the prompt will be changed to just the short description.

The return value is identical to the return value of sizetext() run on the
generated prompt.

=cut

sub makeprompt {
	my $this=shift;
	my $question=shift;
	my $freelines=$this->screenheight - $this->borderheight + 1;
	$freelines += shift if @_;

	my ($text, $lines, $columns)=$this->sizetext(
		$question->extended_description."\n\n".
		$question->description
	);
	
	if ($lines > $freelines) {
		$this->showtext($question, $question->extended_description);
		($text, $lines, $columns)=$this->sizetext($question->description);
	}
	
	return ($text, $lines, $columns);
}

=item showdialog

Displays a dialog. After the first parameters which should point to the question
being displayed, all remaining parameters are passed to whiptail/dialog.

If called in a scalar context, returns whatever dialog outputs to stderr.
If called in a list context, returns the return code of dialog, then the
stderr output.

Note that the return code of dialog is examined, and if the user hit escape
or cancel, this frontend will assume they wanted to back up.

=cut

sub showdialog {
	my $this=shift;
	my $question=shift;
	
	debug debug => "preparing to run dialog. Params are:" ,
		join(",", $this->program, @_);

	# Save stdout, stdin, the open3 below messes with them.
	use vars qw{*SAVEOUT *SAVEIN};
	open(SAVEOUT, ">&STDOUT") || die $!;
	open(SAVEIN, "<&STDIN") || die $!;

	# If warnings are enabled by $^W, they are actually printed to
	# stdout by IPC::Open3 and get stored in $stdout below! 
	# So they must be disabled.
	my $savew=$^W;
	$^W=0;
	
	if (not $this->capb_backup) {
		unshift @_, '--nocancel';
	}
	
	my $sigil=$this->sigil->get($question->priority) if $this->sigil && $question;
	
	my $pid = open3('<&STDIN', '>&STDOUT', \*ERRFH, $this->program,
		'--backtitle', gettext("Debian Configuration"),
		'--title', $sigil.$this->title, @_);
	my $stderr;
	while (<ERRFH>) {
		$stderr.=$_;
	}
	chomp $stderr;

	# Have to put the wait here to make sure $? is set properly.
	wait;
	$^W=$savew;

	# Restore stdout, stdin.
	open(STDOUT, ">&SAVEOUT") || die $!;
	open(STDIN, "<&SAVEIN") || die $!;

	# Now check dialog's return code to see if escape (255 (really -1)) or
	# Cancel (1) were hit. If so, make a note that we should back up.
	#
	# To complicate things, a return code of 1 also means that yes was
	# selected from a yes/no dialog, so we must parse the parameters
	# to see if such a dialog was displayed.
	my $ret=$? >> 8;
	if ($ret == 255 || ($ret == 1 && join(' ', @_) !~ m/--yesno\s/)) {
		$this->backup(1);
	}

	if (wantarray) {
		return $ret, $stderr;
	}
	else {
		return $stderr;
	}
}

=back

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
