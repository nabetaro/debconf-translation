#!/usr/bin/perl -w

=head1 NAME

DebConf::FrontEnd::Dialog - dialog FrontEnd

=cut

=head1 DESCRIPTION

This FrontEnd is for a user interface based on dialog, whiptail, or gdialog.
It will use whichever is available, but prefers to use whiptail if available.
It handles all the messy communication with thse programs.

It currently uses only whiptail, because dialog and gdialog lack --defaultno.

=cut

=head1 METHODS

=cut
   
package Debian::DebConf::FrontEnd::Dialog;
use Debian::DebConf::FrontEnd::Base;
use Debian::DebConf::Element::Dialog::String;
use Debian::DebConf::Element::Dialog::Boolean;
use Debian::DebConf::Element::Dialog::Select;
use Debian::DebConf::Element::Dialog::Text;
use Debian::DebConf::Element::Dialog::Note;
use Debian::DebConf::Element::Dialog::Password;
use Debian::DebConf::Priority;
use Text::Wrap qw(wrap $columns);
use IPC::Open3;
use Fcntl;
use POSIX qw(tmpnam);
use strict;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::FrontEnd::Base);

=head2 new

Creates and returns a new FrontEnd::Dialog object. It will look to see if
whiptail, or dialog, or gdialog are available, in that order. To make it use
dialog, set FORCE_DIALOG in the environment. To make it use gdialog, set
FORCE_GDIALOG in the environment.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless $proto->SUPER::new(@_), $class;

	$self->{interactive}=1;

	# Autodetect if whiptail or dialog is available and set magic numbers.
	if (-x "/usr/bin/whiptail" && ! defined $ENV{FORCE_DIALOG} &&
	    ! defined $ENV{FORCE_GDIALOG}) {
		$self->{program}='whiptail';
		$self->{borderwidth}=5;
		$self->{borderheight}=6;
		$self->{spacer}=1;
		$self->{titlespacer}=10;
		$self->{clearscreen}=1;
	}
#	elsif (-x "/usr/bin/dialog" && ! defined $ENV{FORCE_GDIALOG}) {
#		$self->{program}='dialog';
#		$self->{borderwidth}=4;
#		$self->{borderheight}=4;
#		$self->{spacer}=3;
#		$self->{titlespacer}=4;
#		$self->{clearscreen}=1;
#	}
#	elsif (-x "/usr/bin/gdialog") {
#		$self->{program}='gdialog';
#		$self->{borderwidth}=5;
#		$self->{borderheight}=6;
#		$self->{spacer}=1;
#		$self->{titlespacer}=10;
#	}
	else {
		die "Whiptail is not installed, so the dialog based frontend cannot be used.";
#		die "None of whiptail, dialog, or gdialog is installed, so the dialog based frontend cannot be used.";
	}

	return $self;
}

=head2 makeelement

This overrides the method in the Base FrontEnd, and creates Elements in the
Element::Dialog class. Each data type has a different Element created for it.

=cut

sub makeelement {
	my $this=shift;
	my $question=shift;

	# The type of Element we create depends on the input type of the
	# question.
	my $type=$question->template->type;
	my $elt;
	if ($type eq 'string') {
		$elt=Debian::DebConf::Element::Dialog::String->new;
	}
	elsif ($type eq 'boolean') {
		$elt=Debian::DebConf::Element::Dialog::Boolean->new;
	}
	elsif ($type eq 'select') {
		$elt=Debian::DebConf::Element::Dialog::Select->new;
	}
	elsif ($type eq 'text') {
		$elt=Debian::DebConf::Element::Dialog::Text->new;
	}
	elsif ($type eq 'note') {
		$elt=Debian::DebConf::Element::Dialog::Note->new;
	}
	elsif ($type eq 'password') {
		$elt=Debian::DebConf::Element::Dialog::Password->new;
	}
	else {
		die "Unknown type of element: \"$type\"";
	}
	
	$elt->question($question);
	# Some elements need a handle to their FrontEnd.
	$elt->frontend($this);

	return $elt;
}	

=head2 sizetext

Dialog and whiptail have an annoying property of requiring you specify
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
	$columns = ($ENV{COLUMNS} || 80) - $this->borderwidth;
	$text=wrap('', '', $text);
	my @lines=split(/\n/, $text);
	
	# Now figure out what's the longest line. Look at the title size too.
	my $window_columns=length($this->title) + $this->titlespacer;
	map { $window_columns=length if length > $window_columns } @lines;
	
	return $text, $#lines + 1 + $this->borderheight,
	       $window_columns + $this->borderwidth;
}

=head2 showtext

Pass this some text and it will display the text to the user in
a dialog. If the text is too long to fit in one dialog, it will use a
scrollable dialog.

=cut

sub showtext {
	my $this=shift;
	my $intext=shift;

	my $lines = ($ENV{LINES} || 25);
	my ($text, $height, $width)=$this->sizetext($intext);
	my @lines = split(/\n/, $text);
	my $num;
	my @args=('--msgbox', join(",", @lines));
	if ($lines - 4 - $this->borderheight <= $#lines) {
		$num=$lines - 4 - $this->borderheight;
		if ($this->program eq 'whiptail') {
			# Whiptail can scroll text easily.
			push @args, '--scrolltext';
		}
		else {
			# Dialog has to use a temp file.
			my $name;
			# try new temporary filenames until we get one that
			# didn't already exist; the check should be
			# unnecessary, but you can't be too careful these
			# days.
			do { $name = tmpnam() }
				until sysopen(FH, $name, O_RDWR|O_CREAT|O_EXCL);
			print FH join("\n", @lines);
			close FH;
			@args=("--textbox", $name);
		}
	}
	else {
		$num=$#lines + 1;
	}
	$this->showdialog(@args, $num + $this->borderheight, $width);
	if ($args[0] eq '--textbox') {
		unlink $args[1];
	}
}

=head2 showdialog

Displays a dialog. All parameters are passed to whiptail/dialog.

It returns a list with two elements. The first is the return code of dialog.
The second, anything it outputs to stderr.

=cut

sub showdialog {
	my $this=shift;

	print STDERR "Preparing to show dialog ".(join " ", @_)."\n" if $ENV{DEBCONF_DEBUG};

	# Clear the screen if clearscreen is set.
	if ($this->clearscreen) {
		$this->clearscreen('');
#		system 'clear';
	}

	# Save stdout, stderr, the open3 below messes with them.
	use vars qw{*SAVEOUT *SAVEERR};
	open(SAVEOUT, ">&STDOUT");
	open(SAVEERR, ">&STDERR");

	# If warnings are enabled by $^W, they are actually printed to
	# stdout by IPC::Open3 and get stored in $stdout below! (I have no idea
	# why.) So they must be disabled.
	my $savew=$^W;
	$^W=0;
	
	my $pid = open3('<&STDOUT', '>&STDERR', \*ERRFH, $this->program, 
		'--backtitle', 'Debian Configuration',
		'--title', $this->title, @_);
	my $stderr;	
	while (<ERRFH>) {
		$stderr.=$_;
	}
	chomp $stderr;

	# Have to put the wait here to make sure $? is set properly.
	wait;
	$^W=$savew;
	use strict;

	# Restore stdout, stderr.
	open(STDOUT, ">&SAVEOUT");
	open(STDERR, ">&SAVEERR");

	return ($? >> 8), $stderr;
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
