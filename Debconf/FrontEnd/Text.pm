#!/usr/bin/perl -w

=head1 NAME

Debconf::FrontEnd::Text - Text FrontEnd

=cut

package Debconf::FrontEnd::Text;
use strict;
use Text::Wrap;
use Term::ReadLine;
use Debconf::Gettext;
use base qw(Debconf::FrontEnd::Tty);

local $|=1;

=head1 DESCRIPTION

This FrontEnd is for a simple user interface that uses plain text output. It
uses ReadLine to make the user interface just a bit nicer.

=head1 METHODS

=over 4

=cut

sub init {
	my $this=shift;

	$this->SUPER::init(@_);

	$Term::ReadLine::termcap_nowarn = 1; # Turn off stupid termcap warning.
	$this->readline(Term::ReadLine->new('debian'));
	$this->readline->ornaments(1);
	$this->interactive(1);
	$this->linecount(0);
	
	# Figure out which readline module has been loaded, to tell if
	# prompts must include defaults or not.
	if (Term::ReadLine->ReadLine =~ /::Stub$/) {
		$this->promptdefault(1);
	}
}

=item screenwidth

This method from my base class is overridden, so after the screen width
changes, $Text::Wrap::columns is updated to match.

=cut

sub screenwidth {
	my $this=shift;
	
	$Text::Wrap::columns=$this->SUPER::screenwidth(@_);
}

=item display

Displays text wrapped to fit on the screen. If too much text is displayed at
once, it will page it. If a title has been set and has not yet been displayed,
displays it first.

=cut

sub display {
	my $this=shift;
	my $text=shift;
	
	$this->display_nowrap(wrap('','',$text));
}

=item display_nowrap

Display text, paging if necessary. If a title has been set and has not yet been
displayed, displays it first.

=cut

sub display_nowrap {
	my $this=shift;
	my $text=shift;
	my $notitle=shift;

	# Display any pending title.
	$this->title unless $notitle;

	my @lines=split(/\n/, $text);
	# Silly split elides trailing null matches.
	push @lines, "" if $text=~/\n$/;
	foreach (@lines) {
		if ($this->linecount($this->linecount+1) > $this->screenheight - 2) {
			$this->prompt('['.gettext("More").']', '');
		}
		print "$_\n";
	}
}

=item title

Display a title. Only do so once per title. The title is stored in the title
field of the object. If a value is passed in, this will set the title
instead.

=cut

sub title {
	my $this=shift;

	if (@_) {
		return $this->{title}=shift;
	}

	my $title=$this->{title};
	if ($title) {
		$this->display_nowrap($title."\n".('-' x length($title)). "\n", 1);
	}
	$this->{title}='';
}

=item prompt

Pass it the text to prompt the user with, and an optional default. The
user will be prompted to enter input, and their input returned. If a
title is pending, it will be displayed before the prompt.

=cut

sub prompt {
	my $this=shift;
	my $prompt=(shift)." ";
	my $default=shift;
	my $noshowdefault=shift;
	
	$this->linecount(0);
	my $ret;
	if (! $noshowdefault && $this->promptdefault && $default ne '') {
		$ret=$this->readline->readline($prompt."[$default] ", $default);
	}
	else {
		$ret=$this->readline->readline($prompt, $default);
	}
	$this->readline->addhistory($ret);
	if ($ret eq '' && $this->promptdefault) {
		return $default;
	}
	return $ret;
}

=item prompt_password

Same as prompt, except what the user enters is not echoed to the screen
and the default is never shown in the prompt.

=cut

sub prompt_password {
	my $this=shift;
	my $prompt=shift;
	my $default=shift;
	
	my $attribs=$this->readline->Attribs;
	my $oldfunc=$attribs->{'redisplay_function'};
	$attribs->{'redisplay_function'} = $attribs->{'shadow_redisplay'};
	my $ret=$this->prompt($prompt, $default, 1);
	$attribs->{'redisplay_function'} = $oldfunc;

	return $ret;
}

=item shutdown

Before this frontend is shut down, it needs to prompt the user if some text
has been printed out without a prompt. Otherwise, the rest of the apt/dpkg
run will probably scroll that text offscreen without a guarentee the user has
seen it. 

(This isn't in DESTROY because it doesn't work there. Why, I dunno.)

=cut

sub shutdown {
	my $this=shift;

	if ($this->linecount > 0) {
		$this->display('', '');
	}
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
