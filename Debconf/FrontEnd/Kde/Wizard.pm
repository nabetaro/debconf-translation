#!/usr/bin/perl -w

=head1 NAME

Debconf::FrontEnd::Kde::Wizard - Wizard interface for Kde frontend

=cut

package Debconf::FrontEnd::Kde::Wizard;
use strict;
use utf8;
use Debconf::Log ':all';
use QtCore4;
use QtGui4;
use QtCore4::isa qw(Qt::Widget Debconf::FrontEnd::Kde::Ui_DebconfWizard);
use QtCore4::slots 'goNext' => [], 'goBack' => [], 'goBye' => [];
use Debconf::FrontEnd::Kde::Ui_DebconfWizard;

=head1 DESCRIPTION

This module ties together the WizardUI module, which is automatically
generated and constructs the actual wizard UI, with the Kde FrontEnd.

=head1 METHODS

=over 4

=item NEW

Creates a new object of this class.

=cut
use Data::Dumper;
sub NEW {
	
	my ( $class, $parent ) = @_;
	$class->SUPER::NEW($parent );
	this->{frontend} = $_[3];
	
	my $ui = this->{ui} = $class->setupUi(this);

	my $bNext = $ui->{bNext};
	my $bBack = $ui->{bBack};
	my $bCancel = $ui->{bCancel};
	this->setObjectName("Wizard");
	this->connect($bNext, SIGNAL 'clicked ()', SLOT 'goNext ()');
	this->connect($bBack, SIGNAL 'clicked ()', SLOT 'goBack ()');
	this->connect($bCancel, SIGNAL 'clicked ()', SLOT 'goBye ()');

	this->{ui}->mainFrame->setObjectName("mainFrame");;
}

=item setTitle

Changes the window title.

=cut 

sub setTitle {
	this->{ui}->{title}->setText($_[0]);
}

=item setNextEnabled

Pass a true/false value to enable or disable the next button.

=cut

sub setNextEnabled {
	this->{ui}->{bNext}->setEnabled(shift);
}

=item setBackEnabled

Pass a true/false value to enable or disable the back button.

=cut

sub setBackEnabled {
	this->{ui}->{bBack}->setEnabled(shift);
}

=item goNext

Called then when the Next button is pressed.

=cut

sub goNext {
	debug frontend => "QTF: -- LEAVE EVENTLOOP --------";
	this->{frontend}->goback(0);
	this->{frontend}->win->close;
}

=item goBack

Called when the Back button is pressed.

=cut

sub goBack {
	debug frontend => "QTF: -- LEAVE EVENTLOOP --------";
	this->{frontend}->goback(1);
	this->{frontend}->win->close;
}

sub setMainFrameLayout {
	debug frontend => "QTF: -- SET MAIN LAYOUT --------";
   if(this->{ui}->mainFrame->layout) {
      this->{ui}->mainFrame->layout->DESTROY;
    }
   this->{ui}->mainFrame->setLayout(shift);
}

=item goBye

Called when exiting (?)

=cut

sub goBye {
	debug developer => "QTF: -- LEAVE EVENTLOOP --------";
	this->{frontend}->cancelled(1);
	this->{frontend}->win->close;
}

=back

=head1 AUTHOR

Peter Rockai <mornfall@logisys.dyndns.org>
Sune Vuorela <sune@debian.org>

=cut

1;
