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
	use Gnome2;
};
die "Unable to load Gnome -- is libgnome2-perl installed?\n" if $@;

=head1 DESCRIPTION

This FrontEnd is a Gnome UI for Debconf.

=head1 METHODS

=over 4

=item init

Set up most of the GUI.

=cut

our @ARGV_for_gnome=('--sm-disable');

sub create_druid_page {
	my $this=shift;
	
   	$this->druid_page(Gnome2::DruidPageStandard->new);
	$this->druid_page->set_logo($this->logo);
	$this->druid_page->signal_connect("back", sub {
		$this->goback(1);
		Gtk2->main_quit;
		return 1;
	});
	$this->druid_page->signal_connect("next", sub {
		$this->goback(0);
		Gtk2->main_quit;
		return 1;
	});
	$this->druid_page->signal_connect("cancel", sub { exit });
	$this->druid_page->show;
	$this->druid->append_page($this->druid_page);
	$this->druid->set_page($this->druid_page);
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
		Gnome2::Program->init('GNOME Debconf', '2.0');
		exit(0); # success
	}
	
	my @gnome_sucks=@ARGV;
	@ARGV=@ARGV_for_gnome;
	Gnome2::Program->init('GNOME Debconf', '2.0');
	@ARGV=@gnome_sucks;
	
	$this->SUPER::init(@_);
	$this->interactive(1);
	$this->capb('backup');
	
	$this->win(Gtk2::Window->new("toplevel"));
	$this->win->set_position("center");
	$this->win->set_default_size(600, 400);
	my $hostname = `hostname`;
	$this->win->set_title(to_Unicode(sprintf(gettext("Debconf on %s"), $hostname)));
	$this->win->signal_connect("delete_event", sub { exit });
	
	$this->logo(Gtk2::Gdk::Pixbuf->new_from_file("/usr/share/pixmaps/debian-logo.png"));
	
	$this->druid(Gnome2::Druid->new);
	$this->druid->show;
	$this->win->add($this->druid);
	
	$this->create_druid_page ();
}

=item go

Creates and lays out all the necessary widgets, then runs them to get
input.

=cut

sub go {
        my $this=shift;
	my @elements=@{$this->elements};
	
	my $interactive='';
	foreach my $element (@elements) {
		# Noninteractive elemements have no hboxes.
		next unless $element->hbox;

		$interactive=1;
		$this->druid_page->append_item ("", $element->hbox, "");
	}

	if ($interactive) {
	        $this->druid_page->set_title(to_Unicode($this->title));
		if ($this->capb_backup) {
			$this->druid->set_buttons_sensitive(1, 1, 1, 1);
		}
		else {
			$this->druid->set_buttons_sensitive(0, 1, 1, 1);
		}
		$this->win->show;
		Gtk2->main;
		$this->create_druid_page ();
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

=back

=head1 AUTHOR

Eric Gillespie <epg@debian.org>
Gustavo Noronha Silva <kov@debian.org>

=cut

1
