#!/usr/bin/perl -w
#
# FrontEnd that presents a simple line-at-a-time interface.

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

# Create an input element.
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

# Display text nicely wrapped. If too much text is displayed at once, will
# page it.
sub display {
	my $this=shift;
	my $text=shift;
	
	$this->display_nowrap(wrap('','',$text));
}

# Display text without wrapping but still page it.
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

# Display a title. Only do so once per title.
sub title {
	my $this=shift;
	
	my $title=$this->{'title'};
	if ($title) {
		$this->display_nowrap($title."\n".('-' x length($title)). "\n", 1);
	}
	$this->{'title'}='';
}

# Display a prompt and get input.
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

1
