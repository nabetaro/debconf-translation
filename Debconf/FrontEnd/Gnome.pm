#!/usr/bin/perl -w

=head1 NAME

Debconf::FrontEnd::Gnome - GUI Gnome frontend

=cut

package Debconf::FrontEnd::Gnome;
use strict;
use Debconf::Gettext;
use Debconf::Config;
use base qw{Debconf::FrontEnd};

# Catch this so as not to confuse the poor users if Gtk or Gnome are not
# installed.
eval q{
    use Gtk;
    use Gnome;
};
die "Unable to load Gnome -- is libgnome-perl installed?\n"
	if $@;

=head1 DESCRIPTION

This FrontEnd is a Gnome UI for Debconf.

=head1 METHODS

=head1 METHODS

=over 4

=item init

Set up most of the GUI.

=cut

sub init {
	my $this=shift;
	
	die "Unable to open X display.\n" if not $ENV{"DISPLAY"};
	Gnome->init('DebConf');
	
	$this->SUPER::init(@_);
	
	$this->interactive(1);
	$this->capb('backup');
	
	$this->win(Gtk::Window->new("toplevel"));
	$this->win->set_position(1);
	$this->win->set_default_size(600, 400);
	$this->win->signal_connect("delete_event", sub { exit });
	$this->logo(Gtk::Gdk::ImlibImage->load_image("/usr/share/pixmaps/progeny-icon.png"));
	$this->druid(Gnome::Druid->new);
	$this->druid->show;
	$this->win->add($this->druid);
	$this->druid_page(Gnome::DruidPageStandard->new);
	$this->druid_page->set_logo($this->logo);
	my $color = Gtk::Gdk::Color->parse_color('#006699');
	$this->druid_page->set_bg_color($color);
	$this->druid_page->set_logo_bg_color($color);
								       
	$this->druid_page->signal_connect("back", \&back_cb);
	$this->druid_page->signal_connect("next", \&next_cb);
	$this->druid_page->signal_connect("cancel", sub { exit });
	$this->druid_page->show;
	$this->druid->append_page($this->druid_page);
	$this->mainbox(Gtk::HBox->new(0, 0));
	$this->mainbox->show;
	$this->vbox(Gtk::VBox->new(0, 0));
	$this->vbox->show;
	$this->mainbox->pack_start($this->vbox, 1, 1, 5);
	$this->druid_page->vbox->pack_start($this->mainbox, 1, 1, 0);

	# See comment at the end of this file.
	$SIG{SEGV} = \&SEGFEXIT;
}

my $back_pressed;

sub help {
	my $button = shift;
	my $text = $button->help_text;
	my $dialog = Gnome::Dialog->new("Help", "Button_Ok");
	my $label = Gtk::Label->new($text);
	$label->set_line_wrap(1);
	$label->show;
	$dialog->vbox->add($label);
	$dialog->run_and_close();
}

sub back_cb {
    $back_pressed = 1;
    main_quit Gtk;
    return 1;
}

sub next_cb {
    $back_pressed = 0;
    main_quit Gtk;
    return 1;
}

=item go

Creates and lays out all the necessary widgets, then runs them to get
input.

=cut

sub go {
        my $this=shift;
	my @elements=@{$this->elements};
	
	my $firstwidget='';
	foreach my $element (@elements) {
		# Noninteractive elemements have no widgets.
		next unless $element->widget;
		
		unless ($firstwidget) {
			$firstwidget=$element->widget;
		}
		
		# Main box for all the widgets
		$element->hbox(Gtk::HBox->new(0, 10));
		$element->hbox->show;
		$this->vbox->pack_start($element->hbox, 1, 0, 5);

		# Pack in the short description
		$element->description_label(Gtk::Label->new($element->question->description));
		$element->description_label->show;
		$element->hbox->pack_start($element->description_label, 0, 0, 0);

		# Pack in the element's widget
		$element->hbox->pack_start($element->widget, 1, 1, 0);

		# Pack in the help button unless it's a Note or Text element
		if (not ($element->question->template->type eq "note" or
			 $element->question->template->type eq "text")) {
			if ($element->question->extended_description) {
				$element->help_button(Gtk::Button->new_with_label("Help"));
				$element->help_button->show;
				$element->help_button->help_text = $element->question->extended_description;
				$element->help_button->signal_connect("clicked", \&help,
									$element->question->extended_description);
				my $vbox = Gtk::VBox->new(0, 0);
				$vbox->show;
				$vbox->pack_start($element->help_button, 1, 0, 0);
				$element->hbox->pack_start($vbox, 0, 0, 0);
			}
		}
	}

	if ($firstwidget) {
	        $this->druid_page->set_title($this->title);
		if ($this->capb_backup) {
			$this->druid->set_buttons_sensitive(1, 1, 1);
		}
		else {
			$this->druid->set_buttons_sensitive(0, 1, 1);
		}
		$this->win->show;
		Gtk->main;
		foreach my $element (@elements) {
			next unless $element->widget;
			$this->vbox->remove($element->hbox);
		}
	}
	# Display all elements. This does nothing for gnome
	# elements, but it causes noninteractive elements to do
	# their thing.
	foreach my $element (@elements) {
		$element->show;
	}
	$this->clear;
	return '' if $back_pressed;
	return 1;
}

=item title

Immediatly sets the title of the window, if the window is currently displayed.

=cut

sub title {
	my $this=shift;
	if (@_) {
		my $title=$this->SUPER::title(shift);
		if ($this->win) {
			$this->win->set_title($title);
		}
		return $title;
	}
	else {
		return $this->SUPER::title;
	}
}

# Yes, this is horridly evil, but it causes no harm. Gnome-perl
# has an error in its exit handlers. This error leads to a
# segmentation fault. This only affects the exit handler;
# everything that went before is fine.
# TODO: is this still a bug in unstable? Has a bug been filed on gnome-perl?
sub SEGFEXIT {
        exit(0);
}

=back

=head1 AUTHOR

Eric Gillespie <epg@debian.org>

=cut

1
