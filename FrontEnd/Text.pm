#!/usr/bin/perl -w

=head1 NAME

DebConf::FrontEnd::Text - Text FrontEnd

=cut

=head1 DESCRIPTION

This FrontEnd is for a simple user interface that uses plain text output. It
uses ReadLine to make the user interface just a bit nicer.

=cut

=head1 METHODS

=cut

package Debian::DebConf::FrontEnd::Text;
use Debian::DebConf::FrontEnd::Tty;
use Text::Wrap;
use Term::ReadLine;
use strict;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::FrontEnd::Tty);

local $|=1;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless $proto->SUPER::new(@_), $class;
	$self->{'readline'}=Term::ReadLine->new('debian');
	$self->{'readline'}->ornaments(1);
	$self->{'interactive'}=1;
	return $self;
}

=head2 resize

This method from my base class is overridden, so after the screen size changes,
$Text::Wrap::columns is updated to match.

=cut

sub resize {
	my $this=shift;
	$this->SUPER::resize(@_);
	$Text::Wrap::columns=$this->screenwidth;
}

=head2 display

Displays text wrapped to fit on the screen. If too much text is displayed at
once, it will page it. If a title has been set and has not yet been displayed,
displays it first.

=cut

sub display {
	my $this=shift;
	my $text=shift;
	
	$this->display_nowrap(wrap('','',$text));
}

=head2 display_nowrap

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
		if (++$this->{'linecount'} > $this->screenheight - 2) {
			$this->prompt("[More]");
		}
		print "$_\n";
	}
}

=head2 title

Display a title. Only do so once per title. The title is stored in the title
property of the object. If a value is passed in, this will set the title
instead.

=cut

sub title {
	my $this=shift;

	if (@_) {
		return $this->{'title'}=shift;
	}

	my $title=$this->{'title'};
	if ($title) {
		$this->display_nowrap($title."\n".('-' x length($title)). "\n", 1);
	}
	$this->{'title'}='';
}

=head2 prompt

Pass it the text to prompt the user with, and an optional default. The
user will be prompted to enter input, and their input returned. If a
title is pending, it will be displayed before the prompt.

=cut

sub prompt {
	my $this=shift;
	my $prompt=shift;
	my $default=shift;

	$this->{'linecount'}=0;
	local $_=$this->{'readline'}->readline($prompt, $default);
	$this->{'readline'}->addhistory($_);
	return $_;
}

=head2 prompt_password

Same as prompt, except what the user enters is not echoed to the screen.

=cut

sub prompt_password {
	my $this=shift;
	my $prompt=shift;
	my $default=shift;
	
	my $attribs=$this->{'readline'}->Attribs;
	my $oldfunc=$attribs->{'redisplay_function'};
	$attribs->{'redisplay_function'} = $attribs->{'shadow_redisplay'};
	my $ret=$this->prompt($prompt, $default);
	$attribs->{'redisplay_function'} = $oldfunc;

	return $ret;
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
