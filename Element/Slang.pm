#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Slang - Base Slang Element.  

=cut

=head1 DESCRIPTION

This is a base class for all the Slang Elements. These Elements behave
differently than the elements used by other frontends.

=cut

=head1 PROPERTIES

=cut

=head2 xoffset

The x offset of the element inside its container (if any).

=cut

=head2 yoffset

The y offset of the element inside its container (if any).

=cut

=head2 width

The width of the element.

=cut

=head2 height

The height of the element.

=cut

=head2

=head2 container

The container the element is inside, if any.

=cut

=head2 contents

If this element is a container, this property will contain a list of its
contents.

=cut

=head1 METHODS

=cut

package Debian::DebConf::Element::Slang;
use strict;
use Debian::DebConf::Element; # perlbug
use base qw(Debian::DebConf::Element);

sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self  = bless $proto->SUPER::new(@_), $class;

	$self->contents([]);
	return $self;
}

=head container

Set/get the container this element is inside. Automatically updates the
contents property of the container.

=cut

sub container {
	my $this=shift;

	return $this->{container} unless @_;
	if ($this->{container}) {
		my @contents=grep { $_ ne $this }
			     @{$this->{container}->contents};
		$this->{container}->contents(\@contents);
	}
	if (ref $_[0]) {
		my @contents=(@{$_[0]->contents}, $this);
		$_[0]->contents(\@contents);
	}
	return $this->{container}=$_[0];
}

=head resize

This method is called whenever the layout of the screen needs to be
changed. This method calls the function pointed to by the resize_hook
property, if any. Typically, that function will look at the size of the
element's container, and change the element's position and size
appropriatly.

This method causes any elements contained inside this one to be resized.

=cut

sub resize {
	my $this=shift;

	if (ref $this->resize_hook eq 'SUB') {
		&{$this->resize_hook}(@_);
	}

	map { $_->resize(@_) } @{$this->contents};
}

=head2 x

This returns the absolute x position of the element, taking into account
that it may be inside a container.

=cut

sub x {
	my $this=shift;

	my $container=$this->container;
	if ($container) {
		return $this->xoffset + $this->container->x;
	}
	else {
		return $this->xoffset;
	}
}

=head2 y

This returns the absolute y position of the element, taking into account
that it may be inside a container.

=cut

sub y {
	my $this=shift;

	my $container=$this->container;
	if ($container) {
		return $this->yoffset + $this->container->y;
	}
	else {
		return $this->yoffset;
	}
}

=head2 display

Draw the element on the screen. Its coordinates will have already been set.

If a true value is passed, the element should be drawn highlighted (to
indicate it is the active Element).

This method should be overrided. All it does in this base element is
display any elements contained inside this one.

=cut

sub display {
	my $this=shift;

	map { $_->display(@_) } @{$this->contents};
}

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
