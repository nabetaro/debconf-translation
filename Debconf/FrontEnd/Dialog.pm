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
use Debconf::Encoding qw(wrap $columns width);
use Debconf::Path;
use IPC::Open3;
use POSIX;
use Fcntl;
use base qw(Debconf::FrontEnd::ScreenSize);

=head1 DESCRIPTION

This FrontEnd is for a user interface based on dialog or whiptail.
It will use whichever is available, but prefers to use whiptail if available.
It handles all the messy communication with these programs.

=head1 METHODS

=over 4

=item init

Checks to see if whiptail, or dialog are available, in that
order. To make it use dialog, set DEBCONF_FORCE_DIALOG in the environment.

=cut

sub init {
	my $this=shift;

	$this->SUPER::init(@_);

	# These environment variable screws up at least whiptail with the
	# way we call it. Posix does not allow safe arg passing like
	# whiptail needs.
	delete $ENV{POSIXLY_CORRECT} if exists $ENV{POSIXLY_CORRECT};
	delete $ENV{POSIX_ME_HARDER} if exists $ENV{POSIX_ME_HARDER};
	
	# Detect all the ways people have managed to screw up their
	# terminals (so far...)
	if (! exists $ENV{TERM} || ! defined $ENV{TERM} || $ENV{TERM} eq '') { 
		die gettext("TERM is not set, so the dialog frontend is not usable.")."\n";
	}
	elsif ($ENV{TERM} =~ /emacs/i) {
		die gettext("Dialog frontend is incompatible with emacs shell buffers")."\n";
	}
	elsif ($ENV{TERM} eq 'dumb' || $ENV{TERM} eq 'unknown') {
		die gettext("Dialog frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.")."\n";
	}
	
	$this->interactive(1);
	$this->capb('backup');

	# Autodetect if whiptail or dialog is available and set magic numbers.
	if (Debconf::Path::find("whiptail") && 
	    (! defined $ENV{DEBCONF_FORCE_DIALOG} || ! Debconf::Path::find("dialog")) &&
	    (! defined $ENV{DEBCONF_FORCE_XDIALOG} || ! Debconf::Path::find("Xdialog"))) {
		$this->program('whiptail');
		$this->dashsep('--');
		$this->borderwidth(5);
		$this->borderheight(6);
		$this->spacer(1);
		$this->titlespacer(10);
		$this->columnspacer(3);
		$this->selectspacer(13);
		$this->hasoutputfd(1);
	}
	elsif (Debconf::Path::find("dialog") &&
	       (! defined $ENV{DEBCONF_FORCE_XDIALOG} || ! Debconf::Path::find("Xdialog"))) {
		$this->program('dialog');
		$this->dashsep(''); # dialog does not need (or support) 
		                    # double-dash separation
		$this->borderwidth(7);
		$this->borderheight(6);
		$this->spacer(0);
		$this->titlespacer(4);
		$this->columnspacer(2);
		$this->selectspacer(0);
		$this->hasoutputfd(1);
	}
	elsif (Debconf::Path::find("Xdialog") && defined $ENV{DISPLAY}) {
		$this->program("Xdialog");
		$this->borderwidth(7);
		$this->borderheight(20);
		$this->spacer(0);
		$this->titlespacer(10);
		$this->selectspacer(0);
		$this->columnspacer(2);
		# Depends on its geometry. Anything is possible, but
		# this is reasonable.
		$this->screenheight(200);
	}
	else {
		die gettext("No usable dialog-like program is installed, so the dialog based frontend cannot be used.");
	}

	# Whiptail and dialog can't deal with very small screens. Detect
	# this and fail, forcing use of some other frontend.
	# The numbers were arrived at by experimentation.
	if ($this->screenheight < 13 || $this->screenwidth < 31) {
		die gettext("Dialog frontend requires a screen at least 13 lines tall and 31 columns wide.")."\n";
	}
}

=item sizetext

Dialog and whiptail have an annoying field of requiring you specify
their dimensions explicitly. This function handles doing that. Just pass in
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
	$text=wrap('', '', $text);
	my @lines=split(/\n/, $text);
	
	# Now figure out what's the longest line. Look at the title size
	# too. Note use of width function to count columns, not just
	# characters.
	my $window_columns=width($this->title) + $this->titlespacer;
	map {
		my $w=width($_);
		$window_columns = $w if $w > $window_columns;
	} @lines;
	
	return $text, $#lines + 1 + $this->borderheight,
	       $window_columns + $this->borderwidth;
}

=item hide_escape

Used to hide escaped characters in input text from processing by dialog.

=cut

sub hide_escape {
	my $line = $_;

	# dialog will display "\n" as a literal newline; use zero-width
	# utf-8 characters to avoid this.
	$line =~ s/\\n/\\\xe2\x81\xa0n/g;
	return $line;
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
			print $fh join("\n", map &hide_escape, @lines);
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

sub startdialog {
	my $this=shift;
	my $question=shift;
	my $wantinputfd=shift;
	
	debug debug => "preparing to run dialog. Params are:" ,
		join(",", $this->program, @_);

	# Save stdout, stdin, the open3 below messes with them.
	use vars qw{*SAVEOUT *SAVEIN};
	open(SAVEOUT, ">&STDOUT") || die $!;
	$this->dialog_saveout(\*SAVEOUT);
	if ($wantinputfd) {
		$this->dialog_savein(undef);
	} else {
		open(SAVEIN, "<&STDIN") || die $!;
		$this->dialog_savein(\*SAVEIN);
	}

	# If warnings are enabled by $^W, they are actually printed to
	# stdout by IPC::Open3 and get stored in $stdout below! 
	# So they must be disabled.
	$this->dialog_savew($^W);
	$^W=0;
	
	unless ($this->capb_backup || grep { $_ eq '--defaultno' } @_) {
		if ($this->program ne 'Xdialog') {
			unshift @_, '--nocancel';
		}
		else {
			unshift @_, '--no-cancel';
		}
	}

	if ($this->program eq 'Xdialog' && $_[0] eq '--passwordbox') {
		$_[0]='--password --inputbox'
	}
	
	# Set up a pipe to the output fd, before calling open3.
	use vars qw{*OUTPUT_RDR *OUTPUT_WTR};
	if ($this->hasoutputfd) {
		pipe(OUTPUT_RDR, OUTPUT_WTR) || die "pipe: $!";
		my $flags=fcntl(\*OUTPUT_WTR, F_GETFD, 0);
		fcntl(\*OUTPUT_WTR, F_SETFD, $flags & ~FD_CLOEXEC);
		$this->dialog_output_rdr(\*OUTPUT_RDR);
		unshift @_, "--output-fd", fileno(\*OUTPUT_WTR);
	}
	
	my $backtitle='';
	if (defined $this->info) {
		$backtitle = $this->info->description;
	} else {
		$backtitle = gettext("Package configuration");
	}

	use vars qw{*INPUT_RDR *INPUT_WTR};
	if ($wantinputfd) {
		pipe(INPUT_RDR, INPUT_WTR) || die "pipe: $!";
		autoflush INPUT_WTR 1;
		my $flags=fcntl(\*INPUT_RDR, F_GETFD, 0);
		fcntl(\*INPUT_RDR, F_SETFD, $flags & ~FD_CLOEXEC);
		$this->dialog_input_wtr(\*INPUT_WTR);
	} else {
		$this->dialog_input_wtr(undef);
	}

	use vars qw{*ERRFH};
	my $pid = open3($wantinputfd ? '<&INPUT_RDR' : '<&STDIN', '>&STDOUT',
		\*ERRFH, $this->program,
		'--backtitle', $backtitle,
		'--title', $this->title, @_);
	$this->dialog_errfh(\*ERRFH);
	$this->dialog_pid($pid);
	close OUTPUT_WTR if $this->hasoutputfd;
}

sub waitdialog {
	my $this=shift;

	my $input_wtr=$this->dialog_input_wtr;
	if ($input_wtr) {
		close $input_wtr;
	}
	my $output_rdr=$this->dialog_output_rdr;
	my $errfh=$this->dialog_errfh;
	my $output='';
	if ($this->hasoutputfd) {
		while (<$output_rdr>) {
			$output.=$_;
		}
		my $error=0;
		while (<$errfh>) {
			print STDERR $_;
			$error++;
		}
		if ($error) {
			die sprintf("debconf: %s output the above errors, giving up!", $this->program)."\n";
		}
	}
	else {
		while (<$errfh>) { # ugh
			$output.=$_;
		}
	}
	chomp $output;

	# Have to put the wait here to make sure $? is set properly.
	waitpid($this->dialog_pid, 0);
	$^W=$this->dialog_savew;

	# Restore stdin, stdout. Must be this way round because open3 closed
	# stdin, and if we dup onto stdout first Perl tries to use the free
	# fd 0 as a temporary fd and then warns about reopening STDIN as
	# STDOUT.
	if (defined $this->dialog_savein) {
		open(STDIN, '<&', $this->dialog_savein) || die $!;
	}
	open(STDOUT, '>&', $this->dialog_saveout) || die $!;

	# Now check dialog's return code to see if escape (255 (really -1)) or
	# Cancel (1) were hit. If so, make a note that we should back up.
	#
	# To complicate things, a return code of 1 also means that yes was
	# selected from a yes/no dialog, so we must parse the parameters
	# to see if such a dialog was displayed.
	my $ret=$? >> 8;
	if ($ret == 255 || ($ret == 1 && join(' ', @_) !~ m/--yesno\s/)) {
		$this->backup(1);
		return undef;
	}

	if (wantarray) {
		return $ret, $output;
	}
	else {
		return $output;
	}
}

=item showdialog

Displays a dialog. After the first parameters which should point to the question
being displayed, all remaining parameters are passed to whiptail/dialog.

If called in a scalar context, returns whatever dialog outputs to stderr.
If called in a list context, returns the return code of dialog, then the
stderr output.

Note that the return code of dialog is examined, and if the user hit escape
or cancel, this frontend will assume they wanted to back up. In that case,
showdialog will return undef.

=cut

sub showdialog {
	my $this=shift;
	my $question=shift;

	@_=map &hide_escape, @_;

	# It's possible to ask questions in the middle of a progress bar.
	# However, whiptail doesn't like having two instances of itself
	# trying to talk to the same terminal, so we need to shut the
	# progress bar down temporarily.
	if (defined $this->progress_bar) {
		$this->progress_bar->stop;
	}

	$this->startdialog($question, 0, @_);
	my (@ret, $ret);
	if (wantarray) {
		@ret=$this->waitdialog(@_);
	} else {
		$ret=$this->waitdialog(@_);
	}

	# Restart the progress bar if necessary.
	if (defined $this->progress_bar) {
		$this->progress_bar->start;
	}

	if (wantarray) {
		return @ret;
	} else {
		return $ret;
	}
}

=back

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
