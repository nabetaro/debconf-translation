#!/usr/bin/perl -w

=head1 NAME

Debconf::FrontEnd - base FrontEnd

=cut

package Debconf::FrontEnd;
use strict;
use Debconf::Gettext;
use Debconf::Priority;
use Debconf::Config;
use Debconf::Log ':all';
use base qw(Debconf::Base);

=head1 DESCRIPTION

This is the base of the FrontEnd class. Each FrontEnd presents a
user interface of some kind to the user, and handles generating and
communicating with Elements to form that FrontEnd.

=head1 FIELDS

=over 4

=item elements

A reference to an array that contains all the elements that the FrontEnd
needs to show to the user.

=item interactive

Is this an interactive FrontEnd?

=item capb

Holds any special capabilities the FrontEnd supports.

=item title

The title of the FrontEnd.

=item backup

A flag that Elements can set when they are displayed, to tell the FrontEnd
that the user has indicated they want to back up.

=item capb_backup

This will be set if the confmodule states it has the backup capability.

=back

=head1 METHODS

=over 4

=item init

Sets several of the fields to defaults.

=cut

sub init {
	my $this=shift;
	
	$this->elements([]);
	$this->interactive('');
	$this->capb('');
	$this->title('');
}

=item makeelement

Creates an Element of the type used by this FrontEnd. Pass in the question
that will be bound to the Element. It returns the generated Element, or false
if it was unable to make an Element of the given  ype. 

This may be called as either a class or an object method. 

Normally, it outputs debug codes if creating the Element fails. If failure
is expected, a second pasrameter can be passed with a true value to turn
off those debug messages.

=cut

sub makeelement {
	my $this=shift;
	my $question=shift;
	my $nodebug=shift;

	# Figure out what type of frontend this is.
	my $frontend_type;
	if (ref $this) {
		# Called as object method.
		($frontend_type)=ref($this)=~m/Debconf::FrontEnd::(.*)/;
	}
	else {
		# Called as class method.
		($frontend_type)=$this=~m/Debconf::FrontEnd::(.*)/;
	}
	my $type=$frontend_type.'::'.ucfirst($question->type);

	my $element=eval qq{
		use Debconf::Element::$type;
		Debconf::Element::$type->new(
			question => \$question,
		);
	};
	warn sprintf(gettext("Unable to make element of type %s. Failed because: %s"), $type, $@)
		if $@ && ! $nodebug;
	return if ! ref $element;
	return $element;
}

=item add

Adds an Element to the list to be displayed to the user. Just pass the
Element to add. Note that it detects multiple Elements that point to the
same Question and only adds the first.

=cut

sub add {
	my $this=shift;
	my $element=shift;

	foreach (@{$this->elements}) {
		return if $element->question == $_->question;
	}
	
	$element->frontend($this);
	push @{$this->elements}, $element;
}

=item go

Display accumulated Elements to the user.

The return value of each element's show() method is used to set the value
of the question associated with that element.

This will normally return true, but if the user indicates they want to 
back up, it returns false.

=cut

sub go {
	my $this=shift;
	$this->backup('');
	foreach my $element (@{$this->elements}) {
		my $value=$element->show;
		return if $this->backup && $this->capb_backup;
		$element->question->value($value);
	}
	return 1;
}

=item clear

Clear out the accumulated Elements.

=cut

sub clear {
	my $this=shift;
	
	$this->elements([]);
}

=item default_title

This sets the title field to a default. Pass in the name of the
package that is being configured.

=cut

sub default_title {
	my $this=shift;
	
	$this->title(sprintf(gettext("Configuring %s"), ucfirst shift));
}

=item shutdown

This method should be called before a frontend is shut down.

=cut

sub shutdown {}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
