#!/usr/bin/perl -w

#package Debian::DebConf::FrontEnd::Gtk;
#use Debian::DebConf::FrontEnd::Base;
use Gtk;
use Gtk::Atoms;
use strict;
#use vars qw(@ISA);
#@ISA=qw(Debian::DebConf::FrontEnd::Base);

init Gtk;

my $window;
my $questionframe;
my $child;

sub run {
	# create the window
	$window = new Gtk::Window('toplevel');
	$window->set_title("Debian Configuration Guru");
	$window->set_name("main window");
	$window->set_uposition(20,20);
	$window->set_usize(500,250);

	$window->signal_connect("destroy" => \&Gtk::main_quit);
	$window->signal_connect("delete_event" => \&Gtk::false);

	realize $window;

	# divide into three vertical sections: main, vert bar, buttons
	my $vbox = new Gtk::VBox(0,0);
	$window->add($vbox);
	$vbox->show();

	# first section is two horizontal sections: a piccie, and questions
	my $hbox = new Gtk::HBox(0,0);
	$vbox->pack_start($hbox, 1, 1, 5);
	$hbox->show;

	# the piccie has an aligned frame around it
	my $align = new Gtk::Alignment(0.5,0,0,0);
	$hbox->pack_start($align,0,0,5);
	$align->show();

	my $frame = new Gtk::Frame;
	$frame->set_shadow_type("in");

	$align->add($frame);
	$frame->show;

	my ($debianlogo, $debianlogo_mask) = create_from_xpm Gtk::Gdk::Pixmap($window->window, Gtk::Widget->get_default_style->bg('normal'), "debianlogo.xpm");

	my $pixmap = new Gtk::Pixmap($debianlogo, $debianlogo_mask);
	$frame->add($pixmap);
	show $pixmap;

	# the question frame is next
	$questionframe = new Gtk::Frame;
	$questionframe->set_shadow_type("none");
	$hbox->pack_start($questionframe, 1, 1, 5);
	$questionframe->show();

	# okay, now we're onto the horizontal separator
	my $buttsep = new Gtk::HSeparator();
	$vbox->pack_start($buttsep, 0, 1, 0);
	$buttsep->show();

	# then the buttons at the bottom
	my $buttbox = new Gtk::HBox(0,1);
	$vbox->pack_start($buttbox, 0, 0, 5);
	$buttbox->show();

	my @butts = (new Gtk::Button("Cancel"),
	             new Gtk::Button("Next"),
	             new Gtk::Button("Back"));
	($buttbox->pack_end($_,0,0,5), $_->show) foreach (@butts);
	$butts[0]->signal_connect("clicked", \&Cancel);
	$butts[1]->signal_connect("clicked", \&Next);
	$butts[2]->signal_connect("clicked", \&Back);

	$window->show();

	main Gtk;

	return;
}

sub newques {
	my $newtitle = shift; # string
	my $newchild = shift; # Gtk widget

	$questionframe->remove($child) if (defined $child);
	$child = $newchild;
	$questionframe->add($child);
	$child->show();
	$window->set_title("Debian Configuration Guru -- $newtitle");
	Gtk->gc;
}

sub makelabel {
	my $output = shift;

	my $label = new Gtk::Label($output);

	return $label;
}

sub maketext {
	my $output = shift;

	my $text = new Gtk::Text(undef,undef);
	$text->insert(undef,undef,undef, "$output");
	$text->set_word_wrap(1);

	my $vscroller = new Gtk::VScrollbar($text->vadj);

	my $hbox = new Gtk::HBox(0,0);
	$hbox->pack_start($text, 1,1,0);
	$hbox->pack_start($vscroller, 0,1,0);
	$text->show();
	$vscroller->show();

	return $hbox;
}

sub Element_Text {
	my ($desc, $ext_desc) = @_;
	newques($desc, maketext($ext_desc));
}

sub Element_Note {
	my ($desc, $ext_desc) = @_;
	my $vbox = new Gtk::VBox(0,5);
	my $text = maketext($ext_desc);
	my $label = new Gtk::Label("This note has been saved in your mailbox");
	$vbox->pack_start($text, 1,1,0);
	$vbox->pack_start($label, 0,1,0);
	$text->show(); $label->show();
	newques($desc, $vbox);
}


sub Element_Boolean {
	my ($desc, $ext_desc, $default) = @_;
	my $vbox = new Gtk::VBox(0,5);
	my $text = maketext($ext_desc);
	my $check = new Gtk::CheckButton($desc);
	$check->set_active($default);
	$vbox->pack_start($text, 1,1,0);
	$vbox->pack_start($check, 0,1,0);
	$text->show(); $check->show();
	newques($desc, $vbox);
}

sub Element_Select {
	my ($desc, $ext_desc, $default, @options) = @_;
	my $vbox = new Gtk::VBox(0,5);
	my $text = maketext($ext_desc);
	my $last;
	my $radio;

	$vbox->pack_start($text, 1,1,0);
	$text->show();

	foreach my $opt (@options) {
		if ($last) {
			$radio = new Gtk::RadioButton($opt, $last);
		} else {
			$radio = new Gtk::RadioButton($opt);
		}
		$radio->set_active(1) if ($opt eq $default);
		$vbox->pack_start($radio, 0,0,0);
		$radio->show();
		$last = $radio;
	}

	newques($desc, $vbox);
}

sub Element_String {
	my ($desc, $ext_desc, $default) = @_;
	my $vbox = new Gtk::VBox(0,5);
	my $text = maketext($ext_desc);
	my $entry = new Gtk::Entry;
	$entry->set_text($default);
	$vbox->pack_start($text, 1,1,0);
	$vbox->pack_start($entry, 0,1,0);
	$text->show(); $entry->show();
	newques($desc, $vbox);
}

sub Cancel { callback("cancel"); }
sub Back { callback("back"); }
sub Next { callback("change"); }

sub callback {
	my $button = shift;

	if ($button eq "cancel") {
		Element_Text("test text", <<EOF );
this is a test message. it's not very exciting, but at least it exists. you
could put something interesting here if you cared, but you probably don't.
well, at least, i don't.
hmmm.
EOF
	} elsif ($button eq "back") {
		Element_Select("test select", "this is a select thing. choose one of the options", "baz", "foo", "bar", "baz", "quux", "quuux", "quuuux");
	} else {
		Element_Boolean("test boolean", "this is a test boolean. are you feeling lucky, punk?", 0);	
	}
}

run;
