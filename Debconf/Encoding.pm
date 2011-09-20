#!/usr/bin/perl

=head1 NAME

Debconf::Encoding - Character encoding support for debconf

=head1 DESCRIPTION

This module provides facilities to convert between character encodings for
debconf, as well as other functions to operate on characters.

Debconf uses glibc's character encoding converter via Text::Iconv instead
of perl's internal Encoding conversion library because I'm not really sure
if perls encoding is 100% the same. There could be round-trip errors
between iconv's encodings and perl's, conceivably.

$Debconf::Encoding::charmap holds the user's charmap.

Debconf::Encoding::convert()  takes a charmap and a string encoded in that
charmap, and converts it to the user's charmap.

Debconf::Encoding::wrap is a word-wrapping function, with the same interface
as the one in Text::Wrap (except it doesn't gratuitously unexpand tabs).
If Text::WrapI18N is available, it will be used for proper wrapping of
multibyte encodings, combining and fullwidth characters, and languages that
do not use whitespace between words.

$Debconf::Encoding::columns is used to set the number of columns text is
wrapped to by Debconf::Encoding::wrap

Debconf::Encoding::width returns the number of columns required to display
the given string. If available, Text::CharWidth is used to determine the
width, to support combining and fullwidth characters.

Any of the above can be exported, this module uses the exporter.

=cut

package Debconf::Encoding;

use strict;
use warnings;

our $charmap;
BEGIN {
	no warnings;
	eval q{	use Text::Iconv };
	use warnings;
	if (! $@) {
		# I18N::Langinfo is not even in Debian as I write this, so
		# I will use something that is to get the charmap.
		$charmap = `locale charmap`;
		chomp $charmap;
	}
	
	no warnings;
	eval q{ use Text::WrapI18N; use Text::CharWidth };
	use warnings;
	# mblen has been known to get busted and return large numbers when
	# the wrong version of perl is installed. Avoid an infinite loop
	# in Text::WrapI18n in this case.
	if (! $@ && Text::CharWidth::mblen("a") == 1) {
		# Set up wrap and width functions to point to functions
		# from the modules.
		*wrap = *Text::WrapI18N::wrap;
		*columns = *Text::WrapI18N::columns;
		*width = *Text::CharWidth::mbswidth;
	}
	else {
		# Use Text::Wrap for wrapping, but unexpand tabs.
		require Text::Wrap;
		require Text::Tabs;
		sub _wrap { return Text::Tabs::expand(Text::Wrap::wrap(@_)) }
		*wrap = *_wrap;
		*columns = *Text::Wrap::columns;
		# Cannot just use *CORE::length; perl is too dumb.
		sub _dumbwidth { length shift }
		*width = *_dumbwidth;
	}
}

use base qw(Exporter);
our @EXPORT_OK=qw(wrap $columns width convert $charmap to_Unicode);

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

my $unicode_conv;
sub to_Unicode {
	my $string = shift;
	my $result;

	return $string if utf8::is_utf8($string);
	if (!defined $unicode_conv) {
		$unicode_conv = Text::Iconv->new($charmap, "UTF-8");
	}
	$result = $unicode_conv->convert($string);
	utf8::decode($result);
	return $result;
}

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
