#!/usr/bin/perl -w

BEGIN {
    @INC = grep(!/^\.$/, @INC);
}	

eval q{
    use Gtk;
    use Gnome;
};

die "Unable to load Gnome -- is libgnome-perl installed?\n"
	if $@;

package Debian::DebConf::FrontEnd::Gnome;
use strict;
use Debian::DebConf::Gettext;
use Debian::DebConf::Config;
use Debian::DebConf::FrontEnd; # perlbug
use vars qw{@ISA};
use Debian::DebConf::FrontEnd;

push @ISA, qw{Debian::DebConf::FrontEnd};

sub quit {
    exit;
}

my $back_pressed;

sub help {
    my $button = shift;
    my $text = $button->{help_text};
    my $dialog = new Gnome::Dialog("Help", "Button_Ok");
    my $label = new Gtk::Label($text);
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

sub init {
	my $this=shift;
	$this->SUPER::init(@_);
	die "Unable to open X display.\n" if not $ENV{"DISPLAY"};
	Gnome->init('DebConf'); #or die;
	$this->interactive(1);
	$this->capb('backup');
	$this->{win} = new Gtk::Window("toplevel");
	$this->{win}->set_position(1);
	$this->{win}->set_default_size(600, 400);
	$this->{win}->signal_connect("delete_event", \&quit);
	$this->{logo} = load_image Gtk::Gdk::ImlibImage("/usr/share/pixmaps/progeny-icon.png");
	$this->{druid} = new Gnome::Druid;
	$this->{druid}->show;
	$this->{win}->add($this->{druid});
	$this->{druid_page} = new Gnome::DruidPageStandard;
	$this->{druid_page}->set_logo($this->{logo});
	my $color = Gtk::Gdk::Color->parse_color('#006699');
	$this->{druid_page}->set_bg_color($color);
	$this->{druid_page}->set_logo_bg_color($color);
								       
	$this->{druid_page}->signal_connect("back", \&back_cb);
	$this->{druid_page}->signal_connect("next", \&next_cb);
	$this->{druid_page}->signal_connect("cancel", \&quit);
	$this->{druid_page}->show;
	$this->{druid}->append_page($this->{druid_page});
	$this->{mainbox} = new Gtk::HBox(0, 0);
	$this->{mainbox}->show;
	$this->{vbox} = new Gtk::VBox(0, 0);
	$this->{vbox}->show;
	$this->{mainbox}->pack_start($this->{vbox}, 1, 1, 5);
	$this->{druid_page}->vbox->pack_start($this->{mainbox}, 1, 1, 0);

	# See comment at the end of this file.
	$SIG{SEGV} = \&SEGFEXIT;
}

sub go {
        my $this=shift;
	my @elements=@{$this->{elements}};
	return 1 unless @elements;
	my $firstwidget='';
	foreach my $element (@elements) {
		next unless $element->{widget};
		
		unless ($firstwidget) {
			$firstwidget=$element->{widget};
		}
		
		# Main box for all the widgets
		$element->{hbox} = new Gtk::HBox(0, 10);
		$element->{hbox}->show;
		$this->{vbox}->pack_start($element->{hbox}, 1, 0, 5);

		# Pack in the short description
		$element->{description_label} = new Gtk::Label($element->{question}->description);
		$element->{description_label}->show;
		$element->{hbox}->pack_start($element->{description_label},
					     0, 0, 0);

		# Pack in the element's widget
		$element->{hbox}->pack_start($element->{widget}, 1, 1, 0);

		# Pack in the help button unless it's a Note or Text element
		if (not ($element->{question}->{template}->{type} eq "note" or
			 $element->{question}->{template}->{type} eq "text")) {
			if ($element->{question}->extended_description) {
				$element->{help_button} = new_with_label
				  Gtk::Button("Help");
				$element->{help_button}->show;
				$element->{help_button}->{help_text} =
				  $element->{question}->extended_description;
				$element->{help_button}->signal_connect("clicked", \&help,
									$element->{question}->extended_description);
				my $vbox = new Gtk::VBox(0, 0);
				$vbox->show;
				$vbox->pack_start($element->{help_button}, 1, 0, 0);
				$element->{hbox}->pack_start($vbox, 0, 0, 0);
			}
		}
	}

	my $ret=1;

	if ($firstwidget) {
	        $this->{druid_page}->set_title($this->title);
		if ($this->{capb_backup}) {
		    $this->{druid}->set_buttons_sensitive(1, 1, 1);
		} else {
		    $this->{druid}->set_buttons_sensitive(0, 1, 1);
		}
		$this->{win}->show;
		main Gtk;
		foreach my $element (@elements) {
		    next unless $element->{widget};
		    $this->{vbox}->remove($element->{hbox});
		}
	        if ($back_pressed) {
		    $ret='';
		}
	}
	if ($ret) {
		foreach my $element (@elements) {
		    $element->show;
		}
		foreach my $element (@elements) {
		    next unless $element->widget;
		    $element->question->value($element->value);
		    $element->{question}->flag_isdefault('false');
		}
	    }
	$this->clear;
	return $ret;
}

sub title {
	my $this=shift;
	if (@_) {
		my $title=$this->SUPER::title(shift);
		if ($this->{win}) {
			$this->{win}->set_title($title);
		}
		return $title;
	}
	else {
		return $this->SUPER::title;
	}
}

# Yes, this is horridly evil, but it causes no harm. Gnome-perl
# has an error in its exit handlers. This erro leads to a
# segmentation fault. This only affects the exit handler;
# everything that went before is fine.
sub SEGFEXIT {
        exit(0);
}

1

