#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Slang::Internal::Bar - text bar element

=cut

=head1 DESCRIPTION

This is a colored horizontal bar that can hold text. Useful as a title bar.
The text is displayed centered. The bar itself is always as long as the
container it is inside, and it is displayed at the top of that container.

=cut

=head1 PROPERTIES

=cut

=head2 text

The text to put on the bar.

=cut

=head1 METHODS

=cut

package Debian::DebConf::Element::Slang::Internal::Bar;
use strict;
use base qw(Debian::DebConf::Element::Slang::Internal);

sub height {
	return 1;
}

sub width {
	my $this=shift;

	return $this->container->width if $this->container;
}

sub xoffset {
	return 0;
}

sub yoffset {
	return 0;
}

sub display {
	my $this=shift;
	my ($sl, $x, $y, $width, $text)=(
		$this->frontend->sl, $this->x, $this->y, $this->width,
		$this->text,
	);

	$sl->smg_gotorc($y, $x);
	$sl->smg_set_color($this->frontend->color->{bar});
	$sl->smg_write_nstring("", $width);
	if (defined $text && $text ne '') {
		$sl->smg_gotorc($y, $x + ($width - length($text))/2);
		$sl->smg_write_string($text);
	}
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
