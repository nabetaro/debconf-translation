#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Teletype::Progress - Progress bar in a terminal

=cut

package Debconf::Element::Teletype::Progress;
use strict;
use base qw(Debconf::Element);

=head1 DESCRIPTION

This is an element that can display a progress bar on any terminal. It won't
look particularly good, but it will work.

=cut

sub start {
	my $this=shift;

	$this->frontend->title($this->question->description);
	$this->frontend->display('');
	$this->last(0);
}

sub set {
	my $this=shift;
	my $value=shift;

	$this->progress_cur($value);

	use integer;
	my $new = ($this->progress_cur() - $this->progress_min()) * 100 / ($this->progress_max() - $this->progress_min());
	$this->last(0) if $new < $this->last;
	# prevent verbose output
	return if $new / 10 == $this->last / 10;

	$this->last($new);
	$this->frontend->display("..$new%");

	return 1;
}

sub info {
	return 1;
}

sub stop {
	my $this=shift;

	$this->frontend->display("\n");
	$this->frontend->title($this->frontend->requested_title);
}

1;
