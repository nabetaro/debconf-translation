#!/usr/bin/perl -w

=head1 NAME

Debconf::FrontEnd::Slang - Nice GUI Slang frontend

=cut

package Debconf::FrontEnd::Slang;
use strict;
use Debconf::Gettext;
use Debconf::Config;
use base qw(Debconf::FrontEnd);

# Catch this so it doesn't confuse the poor users if Term::Stool is
# not installed.
eval q{
	use Term::Stool::Screen;
	use Term::Stool::Window;
	use Term::Stool::Dialog;
	use Term::Stool::TitleBar;
	use Term::Stool::HelpBar;
	use Term::Stool::Panel;
	use Term::Stool::Button;
	use Term::Stool::Text;
	use Term::Stool::WrappedText
};
die "Unable to load Term::Stool -- is libterm-stool-perl installed?\n"
	if $@;

=head1 DESCRIPTION

This FrontEnd is a Slang UI for Debconf.

=head1 METHODS

=over 4

=item init

Set up most of the GUI.

=cut

sub init {
	my $this=shift;

	# Detect all the ways people have managed to screw up their
	# terminals (so far...)
	if (! exists $ENV{TERM} || ! defined $ENV{TERM} || $ENV{TERM} eq '') {
		die gettext("TERM is not set, so the Slang frontend is not usable.")."\n";
	}
	elsif ($ENV{TERM} =~ /emacs/i) {
		die gettext("Slang frontend is incompatible with emacs shell buffers")."\n";
	}
	elsif ($ENV{TERM} eq 'dumb') {
		die gettext("Slang frontend will not work on a dumb terminal, an emacs shell buffer, or without a controlling terminal.")."\n";
	}

	$this->SUPER::init(@_);

	$this->interactive(1);
	$this->capb('backup');

	$this->screen(Term::Stool::Screen->new);
	$this->titlebar(Term::Stool::TitleBar->new(
		text => gettext("Debian Configuration"),
	));
	$this->helpbar(Term::Stool::HelpBar->new);
	
	$this->helpwindow(Term::Stool::Window->new(
		title => gettext("Help"),
		resize_hook => sub {
			my $this=shift;
		
			# Resize to take up the bottom half of the screen.
			$this->xoffset(3);
			$this->width($this->container->width - 6);
			$this->yoffset(int(($this->container->height - 6) / 2 + 4));
			$this->height(int(($this->container->height - 6) / 2));
		},
	));
	$this->helptext(Term::Stool::WrappedText->new(
		xoffset => 1,
		yoffset => 0,
		resize_hook => sub {
			my $this=shift;

			# Resize to fit the container its in.
			$this->width($this->container->width - 3);
			$this->height($this->container->height - 2);
		},
	));
	
	$this->button_next(Term::Stool::Button->new(text => gettext("Next")));
	$this->button_back(Term::Stool::Button->new(text => gettext("Back")));
	my $hide_help=gettext("Hide Help");
	my $show_help=gettext("Show Help");
	my $length=length $hide_help;
	$length=length $show_help if length $show_help > $length;
	$this->button_help(Term::Stool::Button->new(
		align => 'right',
		text_hidden => $show_help,
		text_shown => $hide_help,
		width => $length + 4,
		press_hook => sub {
			# Toggle display of the helpwindow.
			if ($this->helpwindow->hidden) {
				Debconf::Config->terse('false');
				$this->helpwindow->hidden(0);
				$this->button_help->text($this->button_help->text_shown);
			}
			else {
				Debconf::Config->terse('true');
				$this->helpwindow->hidden(1);
				$this->button_help->text($this->button_help->text_hidden);
			}
			$this->mainwindow->resize;
			$this->screen->display;
			$this->screen->refresh;
		},
	
	));
	
	if (Debconf::Config->terse eq 'false') {
		$this->button_help->text($this->button_help->text_shown);
	}
	else {
		$this->button_help->text($this->button_help->text_hidden);
		$this->helpwindow->hidden(1);
	}
	
	$this->panel(Term::Stool::Panel->new(
		xoffset => -1,
		yoffset => -1,
		withframe => 0,
		resize_hook => sub {
			my $panel=shift;
			
			# Fill the window, with space for the buttons.
			$panel->width($panel->container->width);
			$panel->height($panel->container->height - 2);

			$this->fillpanel;
		},
	));
	$this->mainwindow(Term::Stool::Dialog->new(
		inside => $this->panel,
		resize_hook => sub {
			my $window=shift;
			
			# Resize to take up the top half of the screen.
			$window->xoffset(2);
			$window->yoffset(2);
			$window->width($window->container->width - 4);
			if ($this->helpwindow->hidden) {			
				$window->height($window->container->height - 4);
			}
			else {
				# Take up top half of screen only.
				$window->height(int(($window->container->height - 6) / 2));
			}	
		},
        ));
	
	$this->mainwindow->buttonbar->add($this->button_next,
		$this->button_back, $this->button_help);
	$this->helpwindow->add($this->helptext);
	$this->screen->add($this->titlebar, $this->mainwindow,
		$this->helpwindow, $this->helpbar);
}

=item go

Creates and lays out all the necessary widgets, then runs them to get
input.

=cut

sub go {
        my $this=shift;
	my @elements=@{$this->elements};

	# Set up all the widgets to be displayed on the panel.
	$this->panel->clear;
	my $firstwidget='';
	foreach my $element (@elements) {
		# Noninteractive elemements have no widgets.
		next unless $element->widgets;
		
		unless ($firstwidget) {
			$firstwidget=$element->widgets->[0];
			
			if (! $this->screen_is_setup) {
				$this->screen_is_setup(1);
				# Make sure slang is up and running, and the screen
				# size is known. Note that this is not done until
				# now so the frontend doesn't pop up in debconf
				# runs where no interactive questions are asked.
				$this->screen->slang_init;
			}
		}
		
		foreach my $widget (@{$element->widgets}) {
			$widget->activate_hook(sub {
				my $this=shift;
			
				# My, this is nasty. We get $element from the
				# closure we're in..
				# First, make sure the short description 
				# is visible.
				$this->container->scrollto($element->widget_description);
				# Now show the long description.
				$element->frontend->helptext->text($element->question->extended_description);
				unless ($element->frontend->helpwindow->hidden) {	
					$element->frontend->helptext->display;
				}
			});
		}
		$element->widget_description(Term::Stool::Text->new(
			text => $element->question->description,
			xoffset => 1,
			resize_hook => sub {
				# Always make all the text visible, if
				# possible.
				my $this=shift;
				my $length=length $this->text;
				my $maxwidth=$this->container->width - $this->x;
				
				if ($length <= $maxwidth) {
					$this->width($length);
				}
				else {
					$this->width($maxwidth);
				}
			},
		));
		$this->panel->add($element->widget_description);
		$this->panel->add(@{$element->widgets});
	}

	# Don't do any of this if there are no interactive widgets to show,
	# since it causes output to the screen.
	if ($firstwidget) {
		# A title was probably set before there even was a
		# mainwindow, so make sure it gets displayed now.
		$this->mainwindow->title($this->title);
		# Make sure everything inside the panel is positioned ok.
		$this->fillpanel;

		# Unless the confmodule can backup, disable the back
		# button.
		if (($this->button_back->disabled && $this->capb_backup) ||
		    (! $this->button_back->disabled && ! $this->capb_backup)) {
			$this->button_back->disabled(! $this->capb_backup);
			$this->button_back->display;
		}

		# Now set it all in motion, with the first widget focused.
		$this->helpbar->push(gettext("Tab and arrow keys move; space drops down lists."));
		$this->helpbar->display;
		$this->panel->display;
		# Force screen refresh because something may have written
		# to the display behind our back.
		# Bah, don't, it looks like crap.
		#$this->screen->force_display;
		$this->screen->run($firstwidget);

		# See which button is active (and thus was pressed), and
		# deactivate it.
		if ($this->button_next->active) {
			$this->backup('');
			$this->button_next->deactivate;
			$this->button_next->display;
		}
		elsif ($this->button_back->active) {
			$this->backup(1);
			$this->button_back->deactivate;
			$this->button_back->display;
		}
		$this->mainwindow->buttonbar->active('');
		# User interaction is done for now.
		$this->helpbar->helpstack([gettext("Working, please wait...")]);
		$this->helpbar->display;
		$this->screen->refresh;
	}

	# Display all elements. This does nothing for slang
	# elements, but it causes noninteractive elements to do
	# their thing.
	foreach my $element (@elements) {
		$element->show;
	}

	return ! $this->backup;
}

=item fillpanel

Called when the panel is resized.

=cut

sub fillpanel {
	my $this=shift;

	my $y=0;
	foreach my $element (@{$this->elements}) {
		$element->widget_description || next;
		$y=$element->resize($y);
		$y++;
		$y++; # a blank line between widget groups.
	}
}

=item title

Immediatly sets the title of the main window, and gets the window to
redisplay itself.

=cut

sub title {
	my $this=shift;

	if (@_) {
		my $title=$this->SUPER::title(shift);
		if ($this->mainwindow) {
			$this->mainwindow->title($title);
			$this->mainwindow->display if $this->screen_is_setup;
		}
		return $title;
	}
	else {
		return $this->SUPER::title;
	}
}

=item shutdown

Reset the screen on shutdown.

=cut

sub shutdown {
	my $this=shift;

	$this->screen->reset if $this->screen;
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
