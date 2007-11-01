#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Gnome::Progress - progress bar widget

=cut

package Debconf::Element::Gnome::Progress;
use strict;
use Gtk2;
use utf8;
use Debconf::Encoding qw(to_Unicode);
use base qw(Debconf::Element::Gnome);

=head1 DESCRIPTION

This is a progress bar widget.

=cut

sub _fraction {
	my $this=shift;

	return (($this->progress_cur() - $this->progress_min()) / ($this->progress_max() - $this->progress_min()));
}

sub start {
	my $this=shift;
	my $description=to_Unicode($this->question->description);
	my $frontend=$this->frontend;

	$this->SUPER::init(@_);
	$this->multiline(1);
	$this->expand(1);

	# Use the short description as the window title.
	$frontend->title($description);

	$this->widget(Gtk2::ProgressBar->new());
	$this->widget->show;
	# Make the progress bar a reasonable height by default.
	$this->widget->set_text(' ');
	$this->addwidget($this->widget);
	$this->addhelp;
}

sub set {
	my $this=shift;
	my $value=shift;

	$this->progress_cur($value);
	$this->widget->set_fraction($this->_fraction);

	# TODO: to support a cancelable progress bar, should return 0 here
	# if the user hit cancel.
	return 1;
}

sub info {
	my $this=shift;
	my $question=shift;

	$this->widget->set_text(to_Unicode($question->description));
	
	# TODO: to support a cancelable progress bar, should return 0 here
	# if the user hit cancel.
	return 1;
}

sub stop {
	my $this=shift;
	my $frontend=$this->frontend;

	$frontend->title($frontend->requested_title);
}

1;
