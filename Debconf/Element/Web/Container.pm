#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Web::Container - A group of releated questions

=cut

package Debconf::Element::Web::Container;
use strict;
use Debconf::Element::Container; # perlbug
use base qw(Debconf::Element::Container);

=head1 DESCRIPTION

This element handles a group of related questions on a web form.

=head1 METHODS

=over 4

=item show

Asks all elements inside it to show themselves and collects the text they
return.

=cut

sub show {
	my $this=shift;
	my @contained=@{$this->contained};
	my $ret='';

	foreach my $elt (@contained) {
		$ret.=$elt->show;
	}
	
	return $ret;
}

=item process

This gets called once the user has entered a value, to process it before        
it is stored.

=cut

sub process {
	my $this=shift;

	# TODO: need to process values of all elements contained within. Ugh.
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
