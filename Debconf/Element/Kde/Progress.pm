#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Kde::Progress - progress bar widget

=cut

package Debconf::Element::Kde::Progress;
use strict;
use Qt;
use base qw(Debconf::Element::Kde);
use Debconf::Encoding qw(to_Unicode);

=head1 DESCRIPTION

This is a progress bar widget.

=cut

sub start {
	my $this=shift;
	my $description=to_Unicode($this->question->description);
	my $frontend=$this->frontend;

	$this->SUPER::create($frontend->frame);

	$this->startsect;
	$this->addhelp;
	$this->adddescription;
	my $vbox = Qt::VBoxLayout($this->widget);

	$this->progress_bar(Qt::ProgressBar($this->progress_max() - $this->progress_min(), $this->cur->top, $description));
	$this->progress_bar->show;
	$this->progress_bar->setSizePolicy(Qt::SizePolicy(1, 0, 0, 0,
		$this->progress_bar->sizePolicy()->hasHeightForWidth()));
	$this->addwidget($this->progress_bar);

	$this->progress_label(Qt::Label($this->cur->top));
	$this->progress_label->show;
	$this->progress_label->setSizePolicy(Qt::SizePolicy(1, 1, 0, 0,
		$this->progress_label->sizePolicy()->hasHeightForWidth()));
	$this->addwidget($this->progress_label);

	$this->endsect;
}

sub set {
	my $this=shift;
	my $value=shift;

	$this->progress_cur($value);
	$this->progress_bar->setProgress($this->progress_cur() - $this->progress_min());
}

sub info {
	my $this=shift;
	my $question=shift;

	$this->progress_label->setText(to_Unicode($question->description));
}

sub stop {
}

1;
