#!/usr/bin/perl -w

=head1 NAME

DebConf::FrontEnd::Slang - Nice GUI Slang frontend

=cut

=head1 DESCRIPTION

This FrontEnd is a Slang UI for DebConf.

=cut

=head1 METHODS

=cut

package Debian::DebConf::FrontEnd::Slang;
use strict;
use Term::Stool;
use Term::Stool::Screen;
use Term::Stool::Window;
use Term::Stool::TitleBar;
use Term::Stool::HelpBar;
use Term::Stool::Panel;
use Term::Stool::Button;
use Debian::DebConf::FrontEnd; # perlbug
use base qw(Debian::DebConf::FrontEnd);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless $proto->SUPER::new(@_), $class;

	# Set up the basic UI.
	$self->screen(Term::Stool::Screen->new);
	$self->titlebar(Term::Stool::TitleBar->new(
		text => "Debian Configuration",
	));
	$self->helpbar(Term::Stool::HelpBar->new(
		helpstack => [ "" ],
	));
	$self->mainwindow(Term::Stool::Window->new(
		xoffset => 2, yoffset => 2, resize_hook => sub {
			my $this=shift;

			# Resize to take up the top half of the screen.
			$this->width($this->container->width - 4);
			$this->height(int(($this->container->height - 6) / 2));
		},
	));
	$self->descwindow(Term::Stool::Window->new(
		title => "Description",
		xoffset => 2, resize_hook => sub {
			my $this=shift;
		
			# Resize to take up the bottom half of the screen.
			$this->width($this->container->width - 4);
			$this->yoffset(int(($this->container->height - 6) / 2 + 4));
			$this->height(int(($this->container->height - 6) / 2));
		},
	));	
	$self->button_next(Term::Stool::Button->new(
		text => "Next", width => 8, resize_hook => sub {
			my $this=shift;

			# Fit at bottom of window, on left hand side.
			$this->yoffset($this->container->height - 3);
			$this->xoffset($this->container->width / 4);
		},
	));
	$self->button_back(Term::Stool::Button->new(
		text => "Back", width => 8, resize_hook => sub {
			my $this=shift;

			# Fit at bottom of window, on right hand side.
			$this->yoffset($this->container->height - 3);
			$this->xoffset($this->container->width / 4 * 3 - $this->width);
		},
	));
	$self->mainwindow->add($self->button_next, $self->button_back);
	$self->screen->add($self->titlebar, $self->mainwindow,
		$self->descwindow, $self->helpbar);
	$self->screen->run($self->button_next);

	return $self;
}

=head2 go


=cut

sub go {
        my $this=shift;

}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
