#!/usr/bin/perl -w

=head1 NAME

DebConf::FrontEnd::Line - line-at-a-time FrontEnd

=cut

=head1 DESCRIPTION

This FrontEnd is for a simple user interface that uses plain text output. It
uses ReadLine to make the user interface just a bit nicer.

=cut

=head1 METHODS

=cut

package Debian::DebConf::FrontEnd::Line;
use Debian::DebConf::FrontEnd::Base;
use Debian::DebConf::Element::Line::String;
use Debian::DebConf::Element::Line::Boolean;
use Debian::DebConf::Element::Line::Select;
use Debian::DebConf::Element::Line::Text;
use Debian::DebConf::Element::Line::Note;
use Text::Wrap;
use Term::ReadLine;
use strict;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::FrontEnd::Base);

local $|=1;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless $proto->SUPER::new(@_), $class;
	$self->{'readline'}=Term::ReadLine->new('debian');
	$self->{'readline'}->ornaments(1);
	return $self;
}

=head2 makeelement

This overrides the method in the Base FrontEnd, and creates Elements in the]
Element::Line class. Each data type has a different Element created for it.

=cut

sub makeelement {
	my $this=shift;
	my $question=shift;

	# The type of Element we create depends on the input type of the
	# question.
	my $type=$question->template->type;
	my $elt;
	if ($type eq 'string') {
		$elt=Debian::DebConf::Element::Line::String->new;
	}
	elsif ($type eq 'boolean') {
		$elt=Debian::DebConf::Element::Line::Boolean->new;
	}
	elsif ($type eq 'select') {
		$elt=Debian::DebConf::Element::Line::Select->new;
	}
	elsif ($type eq 'text') {
		$elt=Debian::DebConf::Element::Line::Text->new;
	}
	elsif ($type eq 'note') {
		$elt=Debian::DebConf::Element::Line::Note->new;
	}
	else {
		die "Unknown type of element: \"$type\"";
	}
	
	$elt->question($question);
	# Some elements need a handle to their FrontEnd.
	$elt->frontend($this);

	return $elt;
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

	my $num=($ENV{LINES} || 25);
	my @lines=split(/\n/, $text);
	# Silly split elides trailing null matches.
	push @lines, "" if $text=~/\n$/;
	foreach (@lines) {
		if (++$this->{linecount} > $num - 2) {
			$this->prompt("[More]");
		}
		print "$_\n";
	}
}

=head2 title

Display a title. Only do so once per title. The title is stored in the title
property of the object.

=cut

sub title {
	my $this=shift;
	
	my $title=$this->{'title'};
	if ($title) {
		$this->display_nowrap($title."\n".('-' x length($title)). "\n", 1);
	}
	$this->{'title'}='';
}

=head2 prompt

Pass it the text to prompt the user with, and an optional default. The user will be
prompted to enter input, and their input returned. If a title is pending, it will be
displayed before the prompt.

=cut

sub prompt {
	my $this=shift;
	my $prompt=shift;
	my $default=shift;

	# Display any pending title.
	$this->title;

	$this->{linecount}=0;
	local $_=$this->{'readline'}->readline($prompt, $default);
	$this->{'readline'}->addhistory($_);
	return $_;
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
