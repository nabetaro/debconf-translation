#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Dialog::Progress - A progress bar in a dialog box

=cut

package Debconf::Element::Dialog::Progress;
use strict;
use base qw(Debconf::Element);

=head1 DESCRIPTION

This is an element that can display a dialog box with a progress bar on it.

=cut

sub _communicate {
	my $this=shift;
	my $data=shift;
	my $dialoginput = $this->frontend->dialog_input_wtr;

	print $dialoginput $data;
}

sub _percent {
	my $this=shift;

	use integer;
	return (($this->progress_cur() - $this->progress_min()) * 100 / ($this->progress_max() - $this->progress_min()));
}

sub start {
	my $this=shift;

	# Use the short description as the window title, matching cdebconf.
	$this->frontend->title($this->question->description);

	my ($text, $lines, $columns);
	if (defined $this->_info) {
		($text, $lines, $columns)=$this->frontend->sizetext($this->_info->description);
	} else {
		# Make sure dialog allocates a bit of extra space, to allow
		# for later PROGRESS INFO commands.
		($text, $lines, $columns)=$this->frontend->sizetext(' ');
	}
	# Force progress bar to full available width, to avoid windows
	# flashing.
	if ($this->frontend->screenwidth - $this->frontend->columnspacer > $columns) {
		$columns = $this->frontend->screenwidth - $this->frontend->columnspacer;
	}

	my @params=('--gauge');
	push @params, $this->frontend->dashsep if $this->frontend->dashsep;
	push @params, ($text, $lines + $this->frontend->spacer, $columns, $this->_percent);

	$this->frontend->startdialog($this->question, 1, @params);

	$this->_lines($lines);
	$this->_columns($columns);
}

sub set {
	my $this=shift;
	my $value=shift;

	$this->progress_cur($value);
	$this->_communicate($this->_percent . "\n");

	return 1;
}

sub info {
	my $this=shift;
	my $question=shift;

	$this->_info($question);

	my ($text, $lines, $columns)=$this->frontend->sizetext($question->description);
	if ($lines > $this->_lines or $columns > $this->_columns) {
		# Start a new, bigger dialog if this won't fit.
		$this->stop;
		$this->start;
	}

	# TODO: escape the "XXX" marker required by dialog somehow? */

	# The line immediately following the marker should be a new
	# percentage, but whiptail (as of 0.51.6-17) looks for a percentage
	# in the wrong buffer and fails to refresh the display as a result.
	# To work around this bug, we give it the current percentage again
	# afterwards to force a refresh.
	$this->_communicate(
		sprintf("XXX\n%d\n%s\nXXX\n%d\n",
			$this->_percent, $text, $this->_percent));

	return 1;
}

sub stop {
	my $this=shift;

	$this->frontend->waitdialog;
	$this->frontend->title($this->frontend->requested_title);
}

1
