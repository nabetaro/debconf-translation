#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::FrontEnd - base FrontEnd

=cut

package Debian::DebConf::FrontEnd;
use strict;
use Debian::DebConf::Gettext;
use Debian::DebConf::Priority;
use Debian::DebConf::Config;
use Debian::DebConf::Log ':all';
use base qw(Debian::DebConf::Base);

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
		($frontend_type)=ref($this)=~m/DebConf::FrontEnd::(.*)/;
	}
	else {
		# Called as class method.
		($frontend_type)=$this=~m/DebConf::FrontEnd::(.*)/;
	}
	debug(developer => "question is $question; question->template is ".$question->template.".\n");
	my $type=$frontend_type.'::'.ucfirst($question->template->type);

	my $element=eval qq{
		use Debian::DebConf::Element::$type;
		Debian::DebConf::Element::$type->new(
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

Display accumulated Elements to the user. The Elements are in the elements
field, and that field is cleared after the Elements are presented.

After showing each element, checks to see if the object's backup field has
been set; if so, doen't display any of the other pending questions (remove them
from the buffer), and returns false. The default is to return true.

The return value of each element's show() method is used to set the value of
the question associated with that element.

=cut

sub go {
	my $this=shift;

	foreach my $element (@{$this->elements}) {
		my $value=$element->show;
		if ($this->backup && $this->capb_backup) {
			$this->clear;
			$this->backup('');
			return;
		}
		$element->question->value($value);
		# Only set isdefault if the element was visible, because we
		# don't want to do it when showing noninteractive select 
		# elements and so on.
		$element->question->flag_isdefault('false')
			if $element->visible;
	}
	$this->clear;
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
