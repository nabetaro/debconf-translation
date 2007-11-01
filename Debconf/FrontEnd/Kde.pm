#!/usr/bin/perl -w

=head1 NAME

Debconf::FrontEnd::Kde - GUI Kde frontend

=cut

package Debconf::FrontEnd::Kde;
use strict;
use utf8;
use Debconf::Gettext;
use Debconf::Config;
BEGIN {
	eval { require Qt };
	die "Unable to load Qt -- is libqt-perl installed?\n" if $@;
	Qt->import;
}
use Debconf::FrontEnd::Kde::Wizard;
use Debconf::Log ':all';
use base qw{Debconf::FrontEnd};
use Debconf::Encoding qw(to_Unicode);

=head1 DESCRIPTION

This FrontEnd is a Kde/Qt UI for Debconf.

=head1 METHODS

=over 4

=item init

Set up the UI. Most of the work is really done by
Debconf::FrontEnd::Kde::Wizard and Debconf::FrontEnd::Kde::WizardUi.

=cut

our @ARGV_KDE=();

sub init {
	my $this=shift;
    
	$this->SUPER::init(@_);
	$this->interactive(1);
	$this->cancelled(0);
	$this->createdelements([]);
	$this->dupelements([]);
	$this->capb('backup');
	$this->need_tty(0);

	# Well I see that the Qt people are just as braindamaged about apps
	# not being allowed to work as the GTK people. You all suck, FYI.    
	if (fork) {
		wait(); # for child
		if ($? != 0) {
			die "DISPLAY problem?\n";
		}
	}
	else {
		$this->qtapp(Qt::Application(\@ARGV_KDE));
		exit(0); # success
	}
	
	# Kde will be initted only if really needed, to avoid being slow,
	# plus avoid nastiness as described in #413509.
	$this->kde_initted(0);
}

sub init_kde {
	my $this=shift;

	return if $this->kde_initted;

	debug frontend => "QTF: initializing app";
	$this->qtapp(Qt::Application(\@ARGV_KDE));
	debug frontend => "QTF: initializing wizard";
	$this->win(Debconf::FrontEnd::Kde::Wizard(undef, undef, $this));
	debug frontend => "QTF: setting size";
	$this->win->resize(620, 430);
	my $hostname = `hostname`;
	chomp $hostname;
	$this->hostname($hostname);
	debug frontend => "QTF: setting title";
	$this->win->setCaption(to_Unicode(sprintf(gettext("Debconf on %s"), $this->hostname)));
	debug frontend => "QTF: initializing main widget";
	$this->toplayout(Qt::HBoxLayout($this->win->mainFrame));
	$this->page(Qt::ScrollView($this->win->mainFrame));
	$this->page->setResizePolicy(&Qt::ScrollView::AutoOneFit());
	$this->page->setFrameStyle(&Qt::Frame::NoFrame());
	$this->frame(Qt::Frame($this->page));
	$this->page->addChild($this->frame);
	$this->toplayout->addWidget($this->page);
	$this->vbox(Qt::VBoxLayout($this->frame, 0, 6, "wizard-main-vbox"));
	$this->space(Qt::SpacerItem(1, 1, 1, 5));
	$this->win->setTitle(to_Unicode(sprintf(gettext("Debconf on %s"), $this->hostname)));

	$this->kde_initted(1);
}

=item go

Creates and lays out all the necessary widgets, then runs them to get
input.

=cut

sub go {
	my $this=shift;
	my @elements=@{$this->elements};
    
	my $interactive='';
	debug frontend => "QTF: -- START ------------------";
	foreach my $element (@elements) {
		next unless $element->can("create");
		$this->init_kde();
		$element->create($this->frame);
		$interactive=1;
		debug frontend => "QTF: ADD: " . $element->question->description;
		$this->vbox->addWidget($element->top);
	}
	
	if ($interactive) {
		foreach my $element (@elements) {
			next unless $element->top;
			debug frontend => "QTF: SHOW: " . $element->question->description;
			$element->top->show;
		}
	
		$this->vbox->addItem($this->space);
	
		if ($this->capb_backup) {
			$this->win->setBackEnabled(1);
		}
		else {
			$this->win->setBackEnabled(0);
		}
		$this->win->setNextEnabled(1);
	
		$this->win->show;
		debug frontend => "QTF: -- ENTER EVENTLOOP --------";
		$this->qtapp->exec;
		debug frontend => "QTF: -- LEFT EVENTLOOP --------";
	
		foreach my $element (@elements) {
			next unless $element -> top;
			debug frontend => "QTF: HIDE: " . $element->question->description;
			$this->vbox->remove($element->top);
			$element->top->hide;
			debug frontend => "QTF: DESTROY: " . $element->question->description;
			$element->destroy;
		}
		
		$this->vbox->removeItem($this->space);
	}
	
	# Display all elements. This does nothing for gnome
	# elements, but it causes noninteractive elements to do
	# their thing.	
	foreach my $element (@elements) {
		$element->show;
	}

	debug frontend => "QTF: -- END --------------------";
	if ($this->cancelled) {
		exit 1;
	}
	return '' if $this->goback;
	return 1;
}

sub progress_start {
	my $this=shift;
	$this->SUPER::progress_start(@_);

	my $element=$this->progress_bar;
	$this->vbox->addWidget($element->top);
	$element->top->show;
	$this->vbox->addItem($this->space);
	# TODO: no backup support yet
	$this->win->setBackEnabled(0);
	$this->win->setNextEnabled(0);
	$this->win->show;
	$this->qtapp->processEvents;
}

sub progress_set {
	my $this=shift;
	my $ret=$this->SUPER::progress_set(@_);

	$this->qtapp->processEvents;

	return $ret;
}

sub progress_info {
	my $this=shift;
	my $ret=$this->SUPER::progress_info(@_);

	$this->qtapp->processEvents;

	return $ret;
}

sub progress_stop {
	my $this=shift;
	my $element=$this->progress_bar;
	$this->SUPER::progress_stop(@_);

	$this->qtapp->processEvents;

	$this->vbox->remove($element->top);
	$element->top->hide;
	$element->destroy;
	$this->vbox->removeItem($this->space);

	if ($this->cancelled) {
		exit 1;
	}
}

=item shutdown

Called to terminate the UI.

=cut

sub shutdown {
	my $this = shift;
	if ($this->kde_initted) {
		$this->win->hide;
		$this->frame->reparent(undef, 0, Qt::Point(0, 0), 0);
		$this->frame(undef);
		$this->win->mainFrame->reparent(undef, 0, Qt::Point(0, 0), 0);
		$this->win->mainFrame(undef);
		$this->win(undef);
		$this->space(undef);
	}
}

=back

=head1 AUTHOR

Peter Rockai <mornfall@logisys.dyndns.org>

=cut

1
