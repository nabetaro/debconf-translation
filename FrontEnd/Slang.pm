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
use lib '../libterm-stool-perl';
use strict;
use Term::Stool;
use Term::Stool::Screen;
use Term::Stool::Window;
use Term::Stool::TitleBar;
use Term::Stool::HelpBar;
use Term::Stool::Panel;
use Term::Stool::Button;
use Term::Stool::Text;
use Debian::DebConf::FrontEnd; # perlbug
use base qw(Debian::DebConf::FrontEnd);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless $proto->SUPER::new(@_), $class;

	$self->interactive(1);

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
			$this->xoffset($this->container->width / 4 * 3
				- $this->width);
		},
	));
	$self->panel(Term::Stool::Panel->new(
		xoffset => 0, yoffset => 0, resize_hook => sub {
			my $this=shift;
			# Fill the window, with space for the buttons.
			$this->width($this->container->width - 2);
			$this->height($this->container->height - 3);
		},
	));
	$self->mainwindow->add($self->panel, $self->button_next,
		$self->button_back);
	$self->screen->add($self->titlebar, $self->mainwindow,
		$self->descwindow, $self->helpbar);
	
	# Force a screen resize so the screen size is known.
	$self->screen->slang_init;
	$self->screen->resize;

	return $self;
}

=head2 title

Setting the frontend's title sets the title of the main window.

=cut

sub title {
	my $this=shift;
	
	return $this->{title} unless @_;
	$this->{'title'} = shift;
	if ($this->mainwindow) {
		$this->mainwindow->title($this->{'title'});
		$this->mainwindow->display;
	}
}

=head2 go

The Elements to display to the user are in the elements property. Each
Element has an associated Question, plus a Term::Stool widget, and those
widgets are laid out on the panel, and the whole thing is displayed. When the
user hits the button, each Element is told to return a value based on what the
user did, and the associated Question is set to that value.

=cut

sub go {
        my $this=shift;

	# Create and lay out all the widgets.
	my $y=0;
	my $firstwidget='';
	foreach my $element (@{$this->elements}) {
		# Alternate some text (the short description)..
		my $text=Term::Stool::Text->new(
			yoffset => $y++,
			xoffset => 1,
			width => $this->panel->width - 4,
			text => substr($element->question->description, 0,
				       $this->panel->width - 4),
		);
		
		# .. with the actual input widget.
		$element->makewidget(
			yoffset => $y++,
			xoffset => 1,
			width => $this->panel->width - 4,
			activate_hook => sub {
				# Set up the widget so when it is
				# activated, it makes sure that the text
				# describing it is also visible.
				$this=shift;
				$this->container->scrollto($text);
			},
		);

		$this->panel->add($text, $element->widget);
		$firstwidget=$element->widget unless $firstwidget;
	}
	
	# Now set it all in motion, with the first widget focused.
	$this->screen->run($firstwidget);

	$this->clear;
	return 1;
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
