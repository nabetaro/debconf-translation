#!/usr/bin/perl -w

=head1 NAME

DebConf::FrontEnd::Slang - Nice GUI Slang frontend

=cut

=head1 DESCRIPTION

This FrontEnd is a Slang UI for DebConf.

=cut

package Debian::DebConf::FrontEnd::Slang;
use lib '../libterm-stool-perl'; # TODO: remove, just for bootstrap.
use strict;
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

=head1 METHODS

=cut

=head2 init

Set up most of the GUI.

=cut

sub init {
	my $this=shift;

	$this->SUPER::init(@_);

	$this->interactive(1);

	$this->screen(Term::Stool::Screen->new);
	$this->titlebar(Term::Stool::TitleBar->new(
		text => "Debian Configuration",
	));
	$this->helpbar(Term::Stool::HelpBar->new);
	$this->mainwindow(Term::Stool::Window->new(
		resize_hook => sub {
			my $this=shift;

			# Resize to take up the top half of the screen.
			$this->xoffset(2);
			$this->yoffset(2);
			$this->width($this->container->width - 4);
			$this->height(int(($this->container->height - 6) / 2));
		},
	));
	$this->descwindow(Term::Stool::Window->new(
		title => "Description",
		resize_hook => sub {
			my $this=shift;
		
			# Resize to take up the bottom half of the screen.
			$this->xoffset(2);
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
			$this->width($this->container->width - 3);
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

			# Clear out any visible description when the focus
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
}

=head2 go

Creates and lays out all the necessary widgets, then runs them to get
input.

=cut

sub go {
        my $this=shift;
	my @elements=@{$this->elements};

	return 1 unless @elements;

	# Set up all the widgets to be displayed on the panel.
	$this->panel->clear;
	my $firstwidget='';
	foreach my $element (@elements) {
		# Noninteractive elemements have no widgets.
		next unless $element->widget;
		
		unless ($firstwidget) {
			$firstwidget=$element->widget;
			
			# Make sure slang is up and running, and the screen
			# size is known. Note that this is not done until
			# now so the frontend doesn't pop up in debconf
			# runs where no interactive questions are asked
			$this->screen->slang_init;
		}
		
		# Make the widget call the element's resize method when it
		# is resized.
		$element->widget->resize_hook(sub { $element->resize });
		$element->widget->activate_hook(sub {
			my $this=shift;
			
			# My, this is nasty. We get $element from the closure
			# we're in..
			# First, make sure the short description is visible.
			$this->container->scrollto($element->widget_description);
			# Now show the long description.
			$element->frontend->desctext->text($element->question->extended_description);
			$element->frontend->desctext->display;
		});
		$element->widget_description(Term::Stool::Text->new(
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
		$this->panel->add($element->widget_description);
		$this->panel->add($element->widget);
	}

	my $ret=1;

	# Don't do any of this if there are no interactive widgets to show.
	if ($firstwidget) {
		$this->mainwindow->title($this->title);
		# Make sure everything inside the panel is positioned ok.
		$this->fillpanel;

		# Unless the confmodule can backup, disable the back
		# button.
		$this->button_back->disabled(! $this->capb_backup);

		# Now set it all in motion, with the first widget focused.
		$this->helpbar->push("Tab and arrow keys move.");
		$this->helpbar->display;
		$this->panel->display;
		$this->screen->run($firstwidget);

		# See which button is active (and thus was pressed).
		if ($this->button_next->active) {
			$this->button_next->deactivate;
			$this->button_next->display;
		}
		elsif ($this->button_back->active) {
			$ret='';
			$this->button_back->deactivate;
			$this->button_back->display;
		}
		# User interaction is done for now.
		$this->helpbar->helpstack(["Working, please wait.."]);
		$this->helpbar->display;
		$this->screen->refresh;
	}

	if ($ret) {
		# Run through the elements, and get the values that were
		# entered and shove them into the questions.
		foreach my $element (@elements) {
			$element->question->value($element->value);
			# Only set isdefault if the element was visible,
			# because we don't want to do it when showing
			# noninteractive select elements and so on.
			$element->question->flag_isdefault('false')
				if $element->visible;
		}
	}

	$this->clear;
	return $ret;
}

=head2 fillpanel

Called when the panel is resized. This sets up the y offset's of all widgets
on the panel. Sometimes a widget group fits on the same line, sometimes not.

=cut

sub fillpanel {
	my $this=shift;
	
	my $y=0;
	foreach my $element (@{$this->elements}) {
		$element->widget_description || next;
		
		$element->widget_description->yoffset($y);
		$element->widget_description->resize;
		$element->resize;
		$y++ unless $element->widget->sameline;
		$element->widget->yoffset($y++);
		$y++; # a blank line between widget groups.
	}
}

=head2 shutdown

Reset the screen on shutdown.

=cut

sub shutdown {
	my $this=shift;

	$this->screen->reset if $this->screen;
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
