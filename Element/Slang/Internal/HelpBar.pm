#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Slang::Internal::HelpBar - help bar element

=cut

=head1 DESCRIPTION

This is a help bar that can appear that the bottom of an element. Text on
the bar is displayed left justified. The help text is stored in a stack;
new text can be pushed onto the stack, and later popped off to display the
old help text.

=cut

=head1 METHODS

=cut

package Debian::DebConf::Element::Slang::Internal::HelpBar;
use strict;
use base qw(Debian::DebConf::Element::Slang::Internal::Bar);

sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self  = bless $proto->SUPER::new(@_), $class;

        $self->helpstack([]);
        return $self;
}

=head2 push

Push help text onto the stack

=cut

sub push {
	my $this=shift;

	push @{$this->helpstack}, @_;
}

=head2 pop

Pop the topmost help text off.

=cut

sub pop {
	my $this=shift;

	pop @{$this->helpstack};
}

sub yoffset {
	my $this=shift;

	return $this->container->height if $this->container;
	return 0;
}

sub display {
	my $this=shift;
	my ($sl, $x, $y, $width, $text)=(
		$this->frontend->sl, $this->x, $this->y, $this->width,
		$this->helpstack->[0],
	);

	$sl->smg_gotorc($y, $x);
	$sl->smg_set_color($this->frontend->color->{bar});
	$sl->smg_write_nstring(defined $text ? $text : "", $width);
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
