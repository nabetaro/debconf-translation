#!/usr/bin/perl -w
#
# FrontEnd that presents a simple line-at-a-time interface
# This inherits from the generic ConfModule and just defines some methods to
# handle commands.

package FrontEnd::Line;
use ConfModule;
use Element::Line::Input;
use Element::Line::Text;
use Element::Line::Note;
use Priority;
use strict;
use vars qw(@ISA);
@ISA=qw(ConfModule);

$|=1;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless $proto->SUPER::new(@_), $class;
	$self->{'readline'}=Term::ReadLine->new('debian');
	$self->{'readline'}->ornaments(1);
	return $self;
}

############################################
# Communication with the configuation module

sub capb {
	my $this=shift;
	$this->{capb}=[@_];

	# I know how to handle back buttons.
	return "backup";
}

# Just store the title, don't display it yet.
sub title {
	my $this=shift;
	$this->{'title'}=join(' ',@_);

	return;
}

# Luckily I don't need to worry about blocks much, since the interface
# is line-at-a-time.
sub beginblock {}	
sub endblock {}

# Add to the list of elements.
sub input {
	my $this=shift;
	my $priority=shift;
	my $question=shift;

	push @{$this->{elements}},
		Element::Line::Input->new($priority, $question);
	
	return;
}

# Add text to the list of elements.
sub text {
	my $this=shift;
	my $priority=shift;
	my $text=join ' ', @_;
	
	push @{$this->{elements}}, 
		Element::Line::Text->new($priority, $text);
	return;
}

# Display a note to the user, which will also make it be saved.
sub note {
	my $this=shift;
	my $priority=shift;
	my $text=join ' ', @_;

	my $note=Element::Line::Note->new($priority, $text);
	$note->frontend($this);
	$note->ask;
	return;
}

# Print out the elements we have pending one at a time and
# get responses from the user for them.
sub go {
	my $this=shift;
	
	foreach my $elt (@{$this->{elements}}) {
		next unless Priority::high_enough($elt->priority);
		# Some elements use helper functions in the frontend
		# so thet need to know what frontend to use.
		$elt->frontend($this);
		$elt->ask;
	}
	$this->{elements}=[];
	return;
}

# Pull a value out of a question.
sub get {
	my $this=shift;
	my $question=shift;
	
	$question=ConfigDb::getquestion($question);
	return $question->value if $question->value ne '';
	return $question->template->default;
}

#####################################
# General frontend-specific functions

use Text::Wrap;
use Term::ReadLine;

# Display text nicely wrapped. If too much text is displayed at once, will
# page it.
sub ui_display {
	my $this=shift;
	my $text=shift;
	
	$this->ui_display_nowrap(wrap('','',$text));
}

# Display text without wrapping but still page it.
sub ui_display_nowrap {
	my $this=shift;
	my $text=shift;
	my $notitle=shift;

	# Display any pending title.
	$this->ui_title unless $notitle;

	my $num=($ENV{LINES} || 25);
	my @lines=split(/\n/, $text);
	# Silly split elides trailing null matches.
	push @lines, "" if $text=~/\n$/;
	foreach (@lines) {
		if (++$this->{linecount} > $num - 2) {
			$this->ui_prompt("[More]");
		}
		print "$_\n";
	}
}

# Display a title. Only do so once per title.
sub ui_title {
	my $this=shift;
	
	my $title=$this->{'title'};
	if ($title) {
		$this->ui_display_nowrap($title."\n".('-' x length($title)). "\n", 1);
	}
	$this->{'title'}='';
}

# Display a prompt and get input.
sub ui_prompt {
	my $this=shift;
	my $prompt=shift;
	my $default=shift;

	# Display any pending title.
	$this->ui_title;

	$this->{linecount}=0;
	local $_=$this->{'readline'}->readline($prompt, $default);
	$this->{'readline'}->addhistory($_);
	return $_;
}

1
