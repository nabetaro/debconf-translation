#!/usr/bin/perl -w

=head1 NAME

DebConf::FrontEnd::Slang - Nice GUI Slang frontend

=cut

=head1 DESCRIPTION

This FrontEnd is a custom Slang UI for DebConf.

=cut

=head1 METHODS

=cut

package Debian::DebConf::FrontEnd::Slang;
use strict;
use Term::Slang;
use Debian::DebConf::FrontEnd::Tty; # perlbug
use base qw(Debian::DebConf::FrontEnd::Tty);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless $proto->SUPER::new(@_), $class;

	$self->showdescs(1);
	$self->sl(Term::Slang->new);
	# Set up slang.
	$self->sl->init_smg;
	$self->sl->SLang_init_tty(-1,0,1);
	$self->sl->SLkp_init;
	
	return $self;
}

=head2 drawscreen

Draw the screen. The general layout is a window containing a scrollable form
on the left that will later be populated by a variety of Elements. A narrower
area on the right will hold the extended description of the Elements (if the
showdescs property is set). Below these areas are some buttons that are used
for controlling debconf.

=cut

sub drawscreen {
}

=head2 go

This overrides to go method in the Base FrontEnd. All visible Elements are
first displayed (via their display methods); and then the first Element is
activated (via its activate method).

While the Element is active, it can do anything it likes, including reading
and responding to keyboard input and writing to the screen. It is expected
that if it receives any input it cannot handle, it should call this FrontEnd's
input method, which may deal with it (see that method for details).

Once an Element deactivates, we figure out what the user did, and move on to
whatever new element they selected, and so the process repeats.

The user may also move onto the button Elements at the bottom of the screen;
if those buttons are pressed, this method will query each Element in turn for
its value, and set the associated Question to the same value, and then return.

=cut

sub go {
        my $this=shift;

}

=head2 input

This method may be called by any Element that has gotten some keyboard input
it doesn't know what to do with. Pass in the input. If the method returns
false, the Element should exit its activate method. Otherwise, it may continue
on as if nothing has happened.

This method handles a variety of navigation keys the user may press.

=cut

sub input {
	my $this=shift;
	my $input=shift;

}

=head2 shutdown

Reset terminal to normal.

=cut

sub shutdown {
	my $this=shift;

	$this->sl->SLang_reset_tty;
	$this->sl->smg_reset_smg;
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
