#!/usr/bin/perl -w

=head1 NAME

Debconf::FrontEnd::Teletype - FrontEnd for any teletype

=cut

package Debconf::FrontEnd::Teletype;
use strict;
use Debconf::Encoding qw(width wrap);
use Debconf::Gettext;
use Debconf::Config;
use base qw(Debconf::FrontEnd::ScreenSize);

=head1 DESCRIPTION

This is a very basic frontend that should work on any terminal, from a real
teletype on up. It also serves as the parent for the Readline frontend.

=head1 FIELDS

=over 4

=item linecount

How many lines have been displayed since the last pause.

=back

=head1 METHODS

=over 4

=cut

sub init {
	my $this=shift;

	$this->SUPER::init(@_);
	$this->interactive(1);
	$this->linecount(0);
}

=item display

Displays text wrapped to fit on the screen. If too much text is displayed at
once, it will page it. If a title has been set and has not yet been displayed,
displays it first.

The important flag, if set, will make it always be shown. If unset, the
text will not be shown in terse mode,

=cut

sub display {
	my $this=shift;
	my $text=shift;
	
	$Debconf::Encoding::columns=$this->screenwidth;
	$this->display_nowrap(wrap('','',$text));
}

=item display_nowrap

Display text, paging if necessary. If a title has been set and has not
yet been displayed, displays it first.

=cut

sub display_nowrap {
	my $this=shift;
	my $text=shift;

	# Terse mode skips all this stuff.
	return if Debconf::Config->terse eq 'true';

	# Silly split elides trailing null matches.
	my @lines=split(/\n/, $text);
	push @lines, "" if $text=~/\n$/;
	
	# Add to the display any pending title.
	my $title=$this->title;
	if (length $title) {
		unshift @lines, $title, ('-' x width $title), '';
		$this->title('');
	}

	foreach (@lines) {
		# If we had to guess at the screenheight, don't bother
		# ever pausing; for all I know this is some real teletype
		# with an infinite height "screen" of fan-fold paper..
		if (! $this->screenheight_guessed &&
		    $this->linecount($this->linecount+1) > $this->screenheight - 2) {
			my $resp=$this->prompt(
				prompt => '['.gettext("More").']',
				default => '',
				completions => [],
			);
			# Hack, there's not a good UI to suggest this is
			# allowed, but you can enter 'q' to break out of
			# the pager.
			if (defined $resp && $resp eq 'q') {
				last;
			}
		}
		print "$_\n";
	}
}

=item prompt

Prompts the user for input, and returns it. If a title is pending,
it will be displayed before the prompt.

This function will return undef if the user opts to skip the question 
(by backing up or moving on to the next question). Anything that uses this
function should catch that and handle it, probably by exiting any
read/validate loop it is in.

The function uses named parameters.

=cut

sub prompt {
	my $this=shift;
	my %params=@_;

	$this->linecount(0);
	local $|=1;
	print "$params{prompt} ";
	my $ret=<STDIN>;
	chomp $ret if defined $ret;
	$this->display_nowrap("\n");
	return $ret;
}

=item prompt_password

Safely prompts for a password; arguments are the same as for prompt.

=cut

sub prompt_password {
	my $this=shift;
	my %params=@_;

	# Kill default: not a good idea for passwords.
	delete $params{default};
	# Force echoing off.
	system('stty -echo 2>/dev/null');
	# Always use this class's version of prompt here, not whatever
	# children put in its place. Only this one is guarenteed to not
	# echo, and work properly for password prompting.
	my $ret=$this->Debconf::FrontEnd::Teletype::prompt(%params);
	system('stty sane 2>/dev/null');
	return $ret;
}

=back

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
