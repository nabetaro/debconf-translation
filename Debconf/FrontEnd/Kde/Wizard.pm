#!/usr/bin/perl -w

=head1 NAME

Debconf::FrontEnd::Kde::Wizard - Wizard interface for Kde frontend

=cut

package Debconf::FrontEnd::Kde::Wizard;
use strict;
use utf8;
use Debconf::Log ':all';
use Qt;
use Qt::isa qw(Debconf::FrontEnd::Kde::WizardUi);
use Qt::slots 'goNext' => [], 'goBack' => [], 'goBye' => [];
use Qt::attributes qw(frontend);
use Debconf::FrontEnd::Kde::WizardUi;

=head1 DESCRIPTION

This module ties together the WizardUI module, which is automatically
generated and constructs the actual wizard UI, with the Kde FrontEnd.

=head1 METHODS

=over 4

=item NEW

Creates a new object of this class.

=cut

sub NEW {
	shift->SUPER::NEW(@_[0..2]);
	frontend = $_[2];
	this->connect(bNext, SIGNAL 'clicked ()', SLOT 'goNext ()');
	this->connect(bBack, SIGNAL 'clicked ()', SLOT 'goBack ()');
	this->connect(bCancel, SIGNAL 'clicked ()', SLOT 'goBye ()');
	this->title->show;
}

=item setTitle

Changes the window title.

=cut 

sub setTitle {
	this->title->setText($_[0]);
}

=item setNextEnabled

Pass a true/false value to enable or disable the next button.

=cut

sub setNextEnabled {
	bNext->setEnabled(shift);
}

=item setBackEnabled

Pass a true/false value to enable or disable the back button.

=cut

sub setBackEnabled {
	bBack->setEnabled(shift);
}

=item goNext

Called then when the Next button is pressed.

=cut

sub goNext {
	debug frontend => "QTF: -- LEAVE EVENTLOOP --------";
	frontend->goback(0);
	Qt::app->exit(0);
}

=item goBack

Called when the Back button is pressed.

=cut

sub goBack {
	debug frontend => "QTF: -- LEAVE EVENTLOOP --------";
	frontend->goback(1);
	Qt::app->exit(0);
}

=item goBye

Called when exiting (?)

=cut

sub goBye {
	debug developer => "QTF: -- LEAVE EVENTLOOP --------";
	frontend->cancelled(1);
	Qt::app->exit (0);
}

=back

=head1 AUTHOR

Peter Rockai <mornfall@logisys.dyndns.org>

=cut

1;
