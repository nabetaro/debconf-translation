#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Slang::Internal::Window - Window element.

=cut

=head1 DESCRIPTION

This is a window element. It is not associated with a Question, and is thus
internal to the Slang FrontEnd.

=cut

=head1 PROPERTIES

=cut

=head2 title

The title of the window.

=cut

=head1 METHODS

=cut

package Debian::DebConf::Element::Slang::Internal::Window;
use strict;
use base qw(Debian::DebConf::Element::Slang::Internal);

sub display {
	my $this=shift;
	my ($sl, $x, $y, $width, $height, $title)=(
		$this->frontend->sl, $this->x, $this->y, $this->width,
		$this->height, $this->title,
	);

	$sl->smg_set_color($this->frontend->color->{dialog});
	$sl->SLsmg_set_char_set(1);
	$sl->SLsmg_fill_region($y+1, $x+1, $height-3, $width-4, ' ');
	$sl->smg_draw_box($y, $x, $height-1, $width-2);
	$sl->smg_gotorc($y, $x+($width + length $title)/2);
	$sl->SLsmg_set_char_set(0);
	if ($title ne '') {
		$sl->smg_gotorc($y, $x+($width-2 - length $title)/2);
		$sl->SLsmg_set_char_set(0);
		$sl->SLsmg_write_string(" ".substr($title, 0, $width - 8)." ");
	}
	# Add one to shadow color because this function for some reason
	# expects color id + 1. Dunno why.
	$sl->smg_set_color_in_region($this->frontend->color->{shadow} + 1,
		$y+$height, $x+1, 1, $width-1);
	$sl->smg_set_color_in_region($this->frontend->color->{shadow} + 1,
		$y+1, $x+$width, $height, 2);

	# Draw everything inside.
	$this->SUPER::display(@_);
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
