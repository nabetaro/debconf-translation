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
use Debian::DebConf::Element::Slang::Internal;
use Debian::DebConf::Element::Slang::Internal::Window;
use Debian::DebConf::FrontEnd::Tty; # perlbug
use base qw(Debian::DebConf::FrontEnd::Tty);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless $proto->SUPER::new(@_), $class;

	$self->startslang;
	# Create the element that represents the entire screen.
	$self->screen(Debian::DebConf::Element::Slang::Internal->new);
	$self->screen->frontend($self);
	$self->screen->xoffset(0);
	$self->screen->yoffset(0);
	$self->resize_hook(sub {
		my $this=shift;

		# Just resize to fit the passed parameters.
		$this->width(shift);
		$this->height(shift);
	});
	# Create the two main windows and put them in the screen.
	my $qwin=Debian::DebConf::Element::Slang::Internal::Window->new;
	$qwin->frontend($self);
	$qwin->title("foo");
	$qwin->container($self->screen);
	$qwin->xoffset(2);
	$qwin->yoffset(2);
	$qwin->resize_hook(sub {
		my $this=shift;

		# Take up the top half of the screen.
		$this->width($this->container->width - 4);
		$this->height(($this->container->height - 4) / 2);
	});
	my $dwin=Debian::DebConf::Element::Slang::Internal::Window->new;
	$dwin->frontend($self);
	$dwin->title("Description");
	$dwin->container($self->screen);
	$self->resize;
	return $self;
}

=head2 startslang

Initialize Slang. This includes setting up all the colors.

=cut

sub startslang {
	my $this=shift;

	$this->sl(Term::Slang->new);
	$this->sl->init_smg;
	$this->sl->SLang_init_tty(-1,0,1);
	$this->sl->smg_init_smg;
	$this->sl->SLkp_init;

	my %colors;
	my $color=0;
	foreach (#color id	foreground	background
		 [background =>	"white",	"blue"],
		 [shadow =>	"gray",		"black"],
		 [bar =>	"black",	"cyan"],
		 [dialog =>	"black",	"white"],
		) {
		$colors{$_->[0]}=$color;
		$this->sl->SLtt_set_color($color++, '', $_->[1], $_->[2]);
	}
	$this->color(\%colors);
	$this->active(1);
}

=head2 resize

We can use slang to get the screen size, and so we do, overriding the more
cludgy way our parent handles this. All Elements are then resized, and the
screen is redrawn.

=cut

sub resize {
	my $this=shift;

	if ($this->active) {
		my ($height, $width)=$this->sl->SLtt_get_screen_size;
		$this->screen->resize($this->screenheight($height - 1),
				      $this->screenwidth($width));
		$this->screen->display;
		$this->sl->smg_refresh;
	}
}

=head2 draw_titlebar

Draw the titlebar at the top of the screen.

=cut

sub draw_titlebar {
	my $this=shift;

	$this->sl->smg_gotorc(0,0);
	$this->sl->smg_set_color($this->color->{bar});
	$this->sl->smg_erase_eol;
	$this->sl->smg_gotorc(0,
		($this->screenwidth - length($this->titlebar)) / 2);
	$this->sl->smg_write_string($this->titlebar);
}

=head2 push_help

Push help text onto the stack. This cases it to be displayed at the bottom
of the screen. Pass in the text.

=cut

sub push_help {
	my $this=shift;

	push @{$this->helpstack}, @_;
	$this->draw_helpbar;
}

=head2 pop_help

Pops the current help text off the stack, causing the previous help text to
be displayed. Returns the popped text.

=cut

sub pop_help {
	my $this=shift;

	my $ret=pop @{$this->helpstack};
	$this->draw_helpbar;
	return $ret;
}

=head2 draw_helpbar

Draw the help bar at the bottom of the screen. The help bar displays the
first element in the array referenced by the helpbar property.

=cut

sub draw_helpbar {
	my $this=shift;

	$this->sl->smg_gotorc($this->screenheight,0);
	$this->sl->smg_set_color($this->color->{bar});
	$this->sl->smg_write_nstring($this->helpstack->[0], $this->screenwidth);
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
	$this->active("");
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
