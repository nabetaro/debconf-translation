#!/usr/bin/perl -w

=head1 NAME

Debconf::FrontEnd::Gnome - GUI Gnome frontend

=cut

package Debconf::FrontEnd::Gnome;
use strict;
use utf8;
use Debconf::Gettext;
use Debconf::Config;
use Debconf::Encoding qw(to_Unicode);
use base qw{Debconf::FrontEnd};

# Catch this so as not to confuse the poor users if Gtk or Gnome are not
# installed.
eval q{
	use Gtk2;
};
die "Unable to load Gtk -- is libgtk2-perl installed?\n" if $@;

=head1 DESCRIPTION

This FrontEnd is a Gnome UI for Debconf.

=head1 METHODS

=over 4

=item init

Set up most of the GUI.

=cut

our @ARGV_for_gnome=('--sm-disable');

sub create_assistant_page {
	my $this=shift;

	$this->assistant_page(Gtk2::VBox->new);
	$this->assistant->append_page($this->assistant_page);

	if ($this->logo) {
		$this->assistant->set_page_header_image($this->assistant_page, $this->logo);
	}

	$this->configure_assistant_page;
	$this->assistant_page->show_all;
}

sub configure_assistant_page {
	my $this=shift;

	$this->assistant->set_page_title($this->assistant_page, to_Unicode($this->title));
	if ($this->capb_backup) {
		$this->assistant->set_page_type($this->assistant_page, 'content');
	} else {
		# Slightly odd, but this is the only way I can see to hide
		# the back button, and it doesn't seem to have any other
		# effects we care about.
		$this->assistant->set_page_type($this->assistant_page, 'intro');
	}
	$this->assistant->set_page_complete($this->assistant_page, 1);
}

sub reset_assistant_page {
	my $this=shift;

	$this->assistant_page($this->assistant->get_nth_page($this->assistant->get_current_page));
	foreach my $element ($this->assistant_page->get_children) {
		$this->assistant_page->remove($element);
	}
}

my $prev_page = 0;

# this gets called on clicking next/previous buttons
sub prepare_callback {
	my ($assistant, $page, $this) = @_;
	my $current_page = $assistant->get_current_page;

	if ($prev_page < $current_page) {
		$this->goback(0);
		if (Gtk2->main_level) {
			Gtk2->main_quit;
		}
	} elsif ($prev_page > $current_page) {
		$this->goback(1);
		if (Gtk2->main_level) {
			Gtk2->main_quit;
		}
	}
	$prev_page = $current_page;
}

sub forward_page_func {
	my ($current_page, $assistant) = @_;

	if ($current_page == $assistant->get_n_pages - 1) {
		return 0;
	} else {
		return $current_page + 1;
	}
}

sub init {
	my $this=shift;
	
	# Ya know, this really sucks. The authors of GTK seemed to just not
	# conceive of a program that can, *gasp*, work even if GTK doesn't
	# load. So this thing throws a fatal, essentially untrappable
	# error. Yeesh. Look how far I must go out of my way to make sure
	# it's not going to destroy debconf..
	if (fork) {
		wait(); # for child
		if ($? != 0) {
			die "DISPLAY problem?\n";
		}
	}
	else {
		@ARGV=@ARGV_for_gnome; # temporary change at first
		Gtk2->init;
		exit(0); # success
	}
	
	my @gnome_sucks=@ARGV;
	@ARGV=@ARGV_for_gnome;
	Gtk2->init;
	@ARGV=@gnome_sucks;
	
	$this->SUPER::init(@_);
	$this->interactive(1);
	$this->capb('backup');
	$this->need_tty(0);
	
	$this->assistant(Gtk2::Assistant->new);
	$this->assistant->set_position("center");
	$this->assistant->set_default_size(600, 400);
	my $hostname = `hostname`;
	chomp $hostname;
	$this->assistant->set_title(to_Unicode(sprintf(gettext("Debconf on %s"), $hostname)));
	$this->assistant->signal_connect("delete_event", sub { exit 1 });

	my $distribution='';
	if (system('type lsb_release >/dev/null 2>&1') == 0) {
		$distribution=lc(`lsb_release -is`);
		chomp $distribution;
	} elsif (-e '/etc/debian_version') {
		$distribution='debian';
	}

	my $logo="/usr/share/pixmaps/$distribution-logo.png";
	if (-e $logo) {
		$this->logo(Gtk2::Gdk::Pixbuf->new_from_file($logo));
	}
	
	$this->assistant->signal_connect("cancel", sub { exit 1 });
	$this->assistant->signal_connect("close", sub { exit 1 });
	$this->assistant->signal_connect("prepare", \&prepare_callback, $this);
	$this->assistant->set_forward_page_func(\&forward_page_func, $this->assistant);
	$this->create_assistant_page();

	$this->assistant->show;
}

=item go

Creates and lays out all the necessary widgets, then runs them to get
input.

=cut

sub go {
        my $this=shift;
	my @elements=@{$this->elements};

	$this->reset_assistant_page;

	my $interactive='';
	foreach my $element (@elements) {
		# Noninteractive elements have no hboxes.
		next unless $element->hbox;

		$interactive=1;
		$this->assistant_page->pack_start($element->hbox, $element->fill, $element->expand, 0);
	}

	if ($interactive) {
		$this->configure_assistant_page;
		if ($this->assistant->get_current_page == $this->assistant->get_n_pages - 1) {
			# Create the next page so that GtkAssistant doesn't
			# hide the Forward button.
			$this->create_assistant_page();
		}
		Gtk2->main;
	}

	# Display all elements. This does nothing for gnome
	# elements, but it causes noninteractive elements to do
	# their thing.
	foreach my $element (@elements) {
		$element->show;
	}

	return '' if $this->goback;
	return 1;
}

sub progress_start {
	my $this=shift;
	$this->SUPER::progress_start(@_);

	$this->reset_assistant_page;

	my $element=$this->progress_bar;
	$this->assistant_page->pack_start($element->hbox, $element->fill, $element->expand, 0);
	# TODO: no backup support yet
	$this->configure_assistant_page;
	$this->assistant->set_page_complete($this->assistant_page, 0);
	$this->assistant->show_all;

	while (Gtk2->events_pending) {
		Gtk2->main_iteration;
	}
}

sub progress_set {
	my $this=shift;

	my $ret=$this->SUPER::progress_set(@_);

	while (Gtk2->events_pending) {
		Gtk2->main_iteration;
	}

	return $ret;
}

sub progress_info {
	my $this=shift;
	my $ret=$this->SUPER::progress_info(@_);

	while (Gtk2->events_pending) {
		Gtk2->main_iteration;
	}

	return $ret;
}

sub progress_stop {
	my $this=shift;
	$this->SUPER::progress_stop(@_);

	while (Gtk2->events_pending) {
		Gtk2->main_iteration;
	}

	if ($this->assistant->get_current_page == $this->assistant->get_n_pages - 1) {
		$this->create_assistant_page();
	}
	# automatically go to the next page now
	$this->assistant->set_current_page($prev_page + 1);
}

=back

=head1 AUTHOR

Eric Gillespie <epg@debian.org>
Gustavo Noronha Silva <kov@debian.org>

=cut

1
