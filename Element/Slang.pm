#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Slang - Base Slang Element.  

=cut

=head1 DESCRIPTION

This is a base class for all the Slang Elements. These elements behave
differently than the elements used by other frontends.

=cut

=head1 PROPERTIES

=cut

=head2 x

The x coordinate the element may start at.

=cut

=head2 y

The y coordinate the element should occupy (elements are all 1 character
tall).

=cut

=head2 width

The maximum width the element can take up on the screen.

=cut

=head2

=head1 METHODS

=cut

package Debian::DebConf::Element::Slang;
use strict;
use base qw(Debian::DebConf::Element);

=head2 display

Draw the element on the screen. Its coordinates will have already been set.
When an element is drawn, it should take care to overwrite everything from
x,y to x+width,y.

If a true value is passed, the element should be drawn highlighted (to
indicate it is the active Element).

=cut

sub display {}

=head2 activate

The element is now active. It will probably enter a loop of processing and
responding to keypresses.

=cut

sub activate {}

=head2 value

When called, this should return the value of the element. This is the value
that gets returned as the answer to the Question linked to the Element.

=cut

sub value {}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
