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
use Term::Stool::WrappedText;
use Debian::DebConf::FrontEnd; # perlbug
use base qw(Debian::DebConf::FrontEnd);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $this  = bless $proto->SUPER::new(@_), $class;

	$this->interactive(1);

	# Set up the basic UI.
	$this->screen(Term::Stool::Screen->new);
	$this->titlebar(Term::Stool::TitleBar->new(
		text => "Debian Configuration",
	));
	$this->helpbar(Term::Stool::HelpBar->new(
		helpstack => [ "Please wait.." ],
	));
	$this->mainwindow(Term::Stool::Window->new(
		xoffset => 2,
		yoffset => 2,
		resize_hook => sub {
			my $this=shift;

			# Resize to take up the top half of the screen.
			$this->width($this->container->width - 4);
			$this->height(int(($this->container->height - 6) / 2));
		},
	));
	$this->descwindow(Term::Stool::Window->new(
		title => "Description",
		xoffset => 2,
		resize_hook => sub {
			my $this=shift;
		
			# Resize to take up the bottom half of the screen.
			$this->width($this->container->width - 4);
			$this->yoffset(int(($this->container->height - 6) / 2 + 4));
			$this->height(int(($this->container->height - 6) / 2));
		},
	));
	$this->desctext(Term::Stool::WrappedText->new(
		xoffset => 1,
		yoffset => 0,
		resize_hook => sub {
			my $this=shift;

			# Resize to fit the container its in.
			$this->width($this->container->width - 4);
			$this->height($this->container->height - 2);
		},
	));
	$this->button_next(Term::Stool::Button->new(
		text => "Next",
		width => 8,
		resize_hook => sub {
			my $this=shift;

			# Fit at bottom of window, on left hand side.
			$this->yoffset($this->container->height - 3);
			$this->xoffset($this->container->width / 4);
		},
	));
	$this->button_back(Term::Stool::Button->new(
		text => "Back",
		width => 8,
		resize_hook => sub {
			my $this=shift;

			# Fit at bottom of window, on right hand side.
			$this->yoffset($this->container->height - 3);
			$this->xoffset($this->container->width / 4 * 3
				- $this->width);
		},
	));
	$this->panel(Term::Stool::Panel->new(
		xoffset => 0,
		yoffset => 0,
		resize_hook => sub {
			my $panel=shift;
			
			# Fill the window, with space for the buttons.
			$panel->width($panel->container->width - 2);
			$panel->height($panel->container->height - 3);

			$this->fillpanel;
		},
		deactivate_hook => sub {
			my $panel=shift;

			# Clear out any showing description when the focus
			# leaves the panel.
			$this->desctext->text('');
			$this->desctext->display;
		},
	));
	$this->mainwindow->add($this->panel, $this->button_next,
		$this->button_back);
	$this->descwindow->add($this->desctext);
	$this->screen->add($this->titlebar, $this->mainwindow,
		$this->descwindow, $this->helpbar);

	return $this;
}

=head2 title

Setting the frontend's title sets the title of the main window.

=cut

sub title {
	my $this=shift;
	
	return $this->{title} unless @_;
	$this->{'title'} = shift;
	if ($this->mainwindow && $this->screen->initialized) {
		$this->mainwindow->title($this->{'title'});
		$this->mainwindow->display;
	}
}

=head2 go

Creates and lays out all the necessary widgets, then runs them to get
input.

=cut

sub go {
        my $this=shift;
	my @elements=@{$this->elements};

	return 1 unless @elements;

	# Make sure slang is up and running, and the screen size is known.
	$this->screen->slang_init;

	# Create all the widgets in the panel.
	$this->panel->clear;
	my $firstwidget='';
	foreach my $element (@elements) {
		$element->makewidget;
		$firstwidget=$element->widget unless $firstwidget;
		# Make the widget call the element's resize method when it
		# is resized.
		$element->widget->resize_hook(sub { $element->resize });
		$element->widget->activate_hook(sub {
			my $this=shift;

			# Make sure the text describing this widget is
			# also visible.
			$this->container->scrollto($this->description);

			# Show the element's description. My, this is
			# nasty. We get $element from the closure we're
			# in..
			$element->frontend->desctext->text(
				$element->question->extended_description);
			$element->frontend->desctext->display;
		});
		$element->widget->description(Term::Stool::Text->new(
			text => $element->question->description,
			xoffset => 1,
			resize_hook => sub {
				# Always make all the text visible, if
				# possible.
				my $this=shift;
				my $length=length $this->text;
				my $maxwidth=$this->container->width - 4;
				
				if ($length <= $maxwidth) {
					$this->width($length);
				}
				else {
					$this->width($maxwidth);
				}
			},
		));
		$this->panel->add($element->widget->description);
		$this->panel->add($element->widget);
	}

	$this->mainwindow->title($this->title);
	# Make sure everything inside the panel is positioned ok.
	$this->fillpanel;

	# Now set it all in motion, with the first widget focused.
	$this->helpbar->push("Tab and arrow keys move.");
	$this->screen->run($firstwidget);
	$this->helpbar->pop;

	$this->clear;
	return 1;
}

=head2 fillpanel

Called when the panel is resized. This sets up the y offset's of all widgets
on the panel. Sometimes a widget group fits on the same line, sometimes not.

=cut

sub fillpanel {
	my $this=shift;
	
	my $y=0;
	foreach my $element (@{$this->elements}) {
		my $widget=$element->widget || next;
		$widget->description->yoffset($y);
		$widget->description->resize;
		$element->resize;
		$y++ unless $widget->sameline;
		$widget->yoffset($y++);
		$y++; # a blank line between widget groups.
	}
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
