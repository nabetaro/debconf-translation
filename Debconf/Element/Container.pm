#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Container - Container input element

=cut

package Debconf::Element::Container;
use Debconf::Gettext;
use Debconf::ConfigDb;
use strict;
use UNIVERSAL qw(isa);
use base qw(Debconf::Element);

=head1 DESCRIPTION

This is a Container input element. A Container is an element that can
hold other elements that are displayed when it is.

=head1 METHODS

=over 4

=item question

This function sets/gets a Container's question field, as usual.
It also handles creating and setting up all the Elements inside the
container.

=cut

sub question {
	my $this=shift;

	if (@_) {
		# This shouldn't happen..
		if (! $this->frontend) {
			die gettext("Container element question method called before frontend was set.");
		}
	
		$this->{'question'}=shift;

		# Create Elements for each Question inside the container
		# Question. However, do _not_ create Elements if they are
		# inside a nested Container. The nested Container takes
		# care of those on its own.
		my @contained=();
		my @subcontainers=();	
		foreach my $question (Debconf::ConfigDb::gettree($this->{'question'})) {
			my $ok=1;
			foreach (@subcontainers) {
				$ok='' if Debconf::ConfigDb::isunder($_, $question);
			}
			next unless $ok;
			
			my $element=$this->frontend->makeelement($question);
			if (isa($element, "Debconf::Element::Container")) {
				push @subcontainers, $element;
			}
			push @contained, $element;
		}
		$this->contained(\@contained);
	}
	return $this->{'question'};
}

=item visible

Containers are visible if any of the items contained in them are visible.
Or are they? This is still being decided -- TODO.

=cut

#sub visible {
#	my $this=shift;
#
#	# TODO: test it.
#
#	# Call parent class to deal with everything else.
#	return $this->SUPER::visible;
#}

=item show

When a container is displayed, it displays all elements inside it.

=cut

sub show {
	my $this=shift;
	my @contained=@{$this->contained};
	
	foreach my $elt (@contained) {
		$elt->show;
	}
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
