#!/usr/bin/perl -w

=head1 NAME

DebConf::FrontEnd::Gtk - gtk FrontEnd

=cut

=head1 DESCRIPTION

This FrontEnd is a user interface based on Gtk. It is styled on the
same lines as the Wizards in Microsoft Windows. (Be afraid..)

=cut

=head1 METHODS

=cut

package Debian::DebConf::FrontEnd::Gtk;
use Debian::DebConf::FrontEnd::Base;
use Debian::DebConf::Element::Gtk::String;
use Debian::DebConf::Element::Gtk::Boolean;
use Debian::DebConf::Element::Gtk::Select;
use Debian::DebConf::Element::Gtk::Text;
use Debian::DebConf::Element::Gtk::Note;
use Gtk;
use Gtk::Atoms;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::FrontEnd::Base);

use strict;

=head2 new

Creates and returns a new FrontEnd::Gtk object.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless $proto->SUPER::new(@_), $class;

	# create the window
	init Gtk;

	my $window = new Gtk::Window('toplevel');
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

	my ($debianlogo, $debianlogo_mask) = create_from_xpm Gtk::Gdk::Pixmap($window->window, Gtk::Widget->get_default_style->bg('normal'), "FrontEnd/debianlogo.xpm");

	my $pixmap = new Gtk::Pixmap($debianlogo, $debianlogo_mask);
	$frame->add($pixmap);
	show $pixmap;

	# the question frame is next
	my $questionframe = new Gtk::Frame;
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
	$butts[0]->signal_connect("clicked", sub { $self->Cancel; });
	$butts[1]->signal_connect("clicked", sub { $self->Next; });
	$butts[2]->signal_connect("clicked", sub { $self->Back; });

	$window->show();

	$self->{window} = $window;
	$self->{questionframe} = $questionframe;
	$self->{result} = "uninitialized";

	return $self;
}

=head2 makeelement

This overrides themethod in the Base FrontEnd, and creates Elements in the
Element::Gtk class. Each data type has a different Element created for it.

=cut

sub makeelement {
	my $this = shift;
	my $question = shift;

	my $type = $question->template->type;
	my $elt;
	if ($type eq 'string') {
		$elt=Debian::DebConf::Element::Gtk::String->new;
	}
	elsif ($type eq 'boolean') {
		$elt=Debian::DebConf::Element::Gtk::Boolean->new;
	}
	elsif ($type eq 'select') {
		$elt=Debian::DebConf::Element::Gtk::Select->new;
	}
	elsif ($type eq 'text') {
		$elt=Debian::DebConf::Element::Gtk::Text->new;
	}
	elsif ($type eq 'note') {
		$elt=Debian::DebConf::Element::Gtk::Note->new;
	}
	else {
		die "Unknown type of element: \"$type\"";
	}

	$elt->question($question);
	$elt->frontend($this);

	return $elt;
}

=head2 newques

=cut

sub newques {
	my $self = shift;
	my $newtitle = shift; # string
	my $newchild = shift; # Gtk widget

	$self->{questionframe}->remove($self->{child})
		if (defined $self->{child});

	$self->{questionframe}->add($newchild);
	$newchild->show();
	$self->{child} = $newchild;

	$self->{questionframe}->realize;

	$self->{window}->set_title("Debian Configuration Guru -- $newtitle");

	Gtk->gc;
	Gtk->main;

	return $self->{result};
}

=head2 maketext

=cut

sub maketext {
	my $self = shift;
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

sub Cancel {
	my $self = shift;
	$self->{result} = "cancel";
	Gtk->main_quit;
}

sub Back {
	my $self = shift;
	$self->{result} = "back";
	Gtk->main_quit;
}
sub Next {
	my $self = shift;
	$self->{result} = "change";
	Gtk->main_quit;
}

=head1 AUTHOR

Anthony Towns <aj@azure.humbug.org.au>

=cut

1
