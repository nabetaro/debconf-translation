#!/usr/bin/perl -w
#
# Base frontend. 
# This inherits from the generic ConfModule and just defines some methods to
# handle commands.

package FrontEnd::Base;
use ConfModule;
use Priority;
use strict;
use vars qw(@ISA);
@ISA=qw(ConfModule);

############################################
# Communication with the configuation module

sub capb {
	my $this=shift;
	$this->{capb}=[@_];
	return;
}

# Just store the title.
sub title {
	my $this=shift;
	$this->{'title'}=join(' ',@_);

	return;
}

# Don't handle blocks.
sub beginblock {}
sub endblock {}

# Print out the elements we have pending one at a time and
# get responses from the user for them. You should override this
# if your frontend supports blocks.
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

1
