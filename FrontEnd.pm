#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::FrontEnd - base FrontEnd

=cut

=head1 DESCRIPTION

This is the base of the FrontEnd class. Each FrontEnd presents a
user interface of some kind to the user, and handles generating and
communicating with Elements to form that FrontEnd. (It so happens that
FrontEnd/Base.pm is a usable non-interactive FrontEnd -- it does not
display any questions or anything else to the user. This may be useful
in some obscure situations.)

=cut

=head1 METHODS

=cut

package Debian::DebConf::FrontEnd;
use Debian::DebConf::Priority;
use Debian::DebConf::Element;
use Debian::DebConf::Config;
use strict;
use vars qw($AUTOLOAD);

=head2 new

Creates a new FrontEnd object and returns it.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{elements}=[];
	$self->{interactive}='';
	bless ($self, $class);
	return $self
}

=head2 makeelement

Create an Element from a Question. Pass in the Question, the Element is
returned.

=cut

sub makeelement {
	my $this=shift;
	my $question=shift;

	return Debian::DebConf::Element->new($question);
}

=head2 add

Add a Question to the list to be displayed to the user. Pass the Question and
text indicating the priority of the Question. This creates an Element and adds
it to the array in the elements property.

=cut

sub add {
	my $this=shift;
	my $question=shift || die "\$question is undefined";
	my $priority=shift;

	my $element=$this->visible($question, $priority);
	push @{$this->{elements}}, $element if $element;
}

=head2

Pass this a question and a priority, it determines if the question is visible.
If so, it returns an input element to use to ask the question.

=cut

sub visible {
	my $this=shift;
	my $question=shift || die "\$question is undefined";
	my $priority=shift;
	
	# Noninteractive frontends never show anything.
	return '' if ! $this->interactive;
	
	# Skip items are unimportant.
	return '' unless Debian::DebConf::Priority::high_enough($priority);
	
	# Set showold to ask even default questions.
	return '' if Debian::DebConf::Config::showold() eq 'false' &&
		$question->flag_isdefault eq 'false';
	
	# Create an input element and ask it.
	my $element=$this->makeelement($question);
	return unless $element->visible;
	
	return $element;
}

=head2 go

Display accumulated Elements to the user. The Elements are in the elements
property, and that property is cleared after the Elements are presented.

=cut

sub go {
	my $this=shift;

	print STDERR "Preparing to ask questions.\n" if $ENV{DEBCONF_DEBUG};

	map { $_->show} @{$this->{elements}};
	$this->clear;
}

=head2 clear

Clear out the accumulated elements.

=cut

sub clear {
	my $this=shift;
	
	$this->{elements}=[];
	return '';
}

=head2 default_title

This sets the title property to a default. Pass in the name of the
package that is being configured.

=cut

sub default_title {
	my $this=shift;
	
	$this->title("Configuring ".ucfirst(shift));
}

# Set/get property.
sub AUTOLOAD {
	my $this=shift;
	my $property = $AUTOLOAD;
	$property =~ s|.*:||; # strip fully-qualified portion
			
	$this->{$property}=shift if @_;
	return $this->{$property};
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
