#!/usr/bin/perl -w
#
# FrontEnd that presents a simple dialog interface, using whiptail (or dialog)
# This inherits from the generic FrontEnd and just defines some methods to
# handle commands.

package Debian::DebConf::FrontEnd::Dialog;
use Debian::DebConf::FrontEnd::Base;
use Debian::DebConf::Priority;
use Text::Wrap qw(wrap $columns);
use IPC::Open3;
use strict;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::FrontEnd::Base);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless $proto->SUPER::new(@_), $class;
	
	# Autodetect if whiptail or dialog is available and set magic numbers.
	if (-x "/usr/bin/whiptail" && ! defined $ENV{FORCE_DIALOG}) {
		$self->{program}='whiptail';
		$self->{borderwidth}=5;
		$self->{borderheight}=6;
		$self->{spacer}=1;
		$self->{titlespacer}=10;
	}
	elsif (-x "/usr/bin/dialog") {
		$self->{program}='dialog';
		$self->{borderwidth}=4;
		$self->{borderheight}=4;
		$self->{spacer}=3;
		$self->{titlespacer}=4;
	}
	else {
		die "Neither whiptail nor dialog is installed, so the dialog based frontend cannot be used.";
	}

	# Things look better in an xterm if I clear the screen now. It cuts
	# down on the nasty screen flickering.
	system 'clear';

	return $self;
}

# Dialog and whiptail have an annoying property of requiring you specify
# their dimentions explicitly. This function handles doing that. Just pass in
# the text that will be displayed in the dialog and then the title of the
# dialog, and it will spit out new text, formatted nicely, then the height for
# the dialog, and then the width for the dialog.
sub sizetext {
	my $this=shift;
	my $title=shift;	
	my $text=shift;
	
	# Try to guess how many lines the text will take up in the dialog.
	# This is difficult because long lines are wrapped. So what I'll do
	# is pre-wrap the text and then just look at the number of lines it
	# takes up.
	$columns = ($ENV{COLUMNS} || 80) - $this->borderwidth;
	$text=wrap('', '', $text);
	my @lines=split(/\n/, $text);
	
	# Now figure out what's the longest line. Look at the title size too.
	my $window_columns=length($title) + $this->titlespacer;
	map { $window_columns=length if length > $window_columns } @lines;
	
	return $text, $#lines + 1 + $this->borderheight,
	       $window_columns + $this->borderwidth;
}

# Pass this a title and some text and it will display the text to the user in
# a dialog. If the text is too long to fit in one dialog, it will use as many
# as are required.
sub showtext {
	my $this=shift;
	my $title=shift;
	my $intext=shift;

	my $lines = ($ENV{LINES} || 25);
	my ($text, $height, $width)=$this->sizetext($title, $intext);
	my @lines = split(/\n/, $text);
	for (my $c = 0; $c <= $#lines; $c += $lines - 4 - $this->borderheight) {
		my ($text, $num);
		if ($c + $lines - 4 - $this->borderheight <= $#lines) {
			$num=$lines - 4 - $this->borderheight;
			$text=join("\n", @lines[$c..$c + $num]);
		}
		else {
			$num=$#lines - $c + 1;
			$text=join("\n", @lines[$c..$#lines]);
		}
		$this->showdialog($title, "--msgbox", $text,
			$num + $this->borderheight, $width);
	}
}

# Shows a dialog. The first parameter is the dialog title (not to be
# confused with the frontend's main title). The remainder are passed to
# whiptail/dialog.
# 
# It returns a list consiting of the return code of whiptail and anything
# whiptail outputs to stderr.
sub showdialog {
	my $this=shift;
	my $title=shift;

	# Save stdout, stderr, the open3 below messes with them.
	use vars qw{*SAVEOUT *SAVEERR};
	open(SAVEOUT, ">&STDOUT");
	open(SAVEERR, ">&STDERR");

	# If warnings are enabled by $^W, they are actually printed to
	# stdout by IPC::Open3 and get stored in $stdout below! (I have no idea
	# why.) So they must be disabled.
	my $savew=$^W;
	$^W=0;
	
	my $pid = open3('<&STDOUT', '>&STDERR', \*ERRFH, $this->{program}, 
		'--backtitle', $this->{title}, '--title', $title, @_);
	my $stderr;		
	while (<ERRFH>) {
		$stderr.=$_;
	}
	chomp $stderr;

	# Have to put the wait here to makie sure $? is set properly.
	wait;

	$^W=$savew;
	use strict;

	# Restore stdout, stderr.
	open(STDOUT, ">&SAVEOUT");
	open(STDERR, ">&SAVEERR");

	return ($? >> 8), $stderr;
}

1
