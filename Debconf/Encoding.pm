#!/usr/bin/perl

=head1 NAME

Debconf::Encoding - Character encoding support for debconf

=head1 DESCRIPTION

This module profides facilities to convert between character encodings for
debconf.

It uses Text::Iconv instead of perl's internal Encoding conversion library
because I'm not really sure if perls encoding is 100% the same. There could be
round-trip errors between iconv's encodings and perl's, conceivably.

$Debconf::Encoding::charmap holds the user's charmap.

Debconf::Encoding::convert()  takes a charmap and a string encoded in that
charmap, and converts it to the user's charmap.

=cut

package Debconf::Encoding;

use strict;
use warnings;

our $charmap;
BEGIN {
	# This module is not part of the base system, so don't demand it.
	no warnings;
	eval "use Text::Iconv";
	use warnings;
	if (! $@) {
		# I18N::Langinfo is not even in Debian as I write this, so
		# I will use something that is to get the charmap.
		$charmap = `locale charmap`;
		chomp $charmap;
	}
}

my $converter;
my $old_input_charmap;
sub convert {
	my $input_charmap = shift;
	my $string = shift;
	
	return unless defined $charmap;
	
	# The converter object is cached.
	if (! defined $old_input_charmap || 
	    $input_charmap ne $old_input_charmap) {
		$converter = Text::Iconv->new($input_charmap, $charmap);
		$old_input_charmap = $input_charmap;
	}
	return $converter->convert($string);
}

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1

