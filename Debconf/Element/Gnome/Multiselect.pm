#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Gnome::Multiselect - a check list in a dialog box

=cut

package Debconf::Element::Gnome::Multiselect;
use strict;
use Gtk2;
use utf8;
use Debconf::Encoding qw(to_Unicode);
use base qw(Debconf::Element::Gnome Debconf::Element::Multiselect);

sub init {
	my $this=shift;
	my @choices = map { to_Unicode($_) } $this->question->choices_split;
        my %default=map { to_Unicode($_) => 1 } $this->translate_default;

	$this->SUPER::init(@_);
	$this->multiline(1);

	$this->adddescription;

        $this->widget(Gtk2::ScrolledWindow->new);
        $this->widget->show;
        $this->widget->set_policy('automatic', 'automatic');
	
	my $list_store = Gtk2::ListStore->new ('Glib::String');

	my $column = Gtk2::TreeViewColumn->new_with_attributes ('Choices',
								Gtk2::CellRendererText->new,
								'text', 0); 
	$this->list_view(Gtk2::TreeView->new ($list_store));
	my $list_selection = $this->list_view->get_selection ();
	$list_selection->set_mode ('multiple');
	$this->list_view->set_headers_visible (0);
	$this->list_view->append_column ($column);
	$this->list_view->show;

	$this->widget->add ($this->list_view);

        for (my $i=0; $i <= $#choices; $i++) {
	    my $iter = $list_store->append ();
	    $list_store->set ($iter, 0, $choices[$i]);
	    if ($default{$choices[$i]}) {
		$list_selection->select_iter ($iter);
	    }
	}
	$this->addwidget($this->widget);
	$this->tip( $this->list_view);
	$this->addhelp;

	# we want to be both expanded and filled
	$this->fill(1);
	$this->expand(1);

}

=item value

The value is just the value field of the widget, translated back to the C
locale.

=cut

sub value {
	my $this=shift;
	my $list_view = $this->list_view;
	my $list_store = $list_view->get_model ();
	my $list_selection = $list_view->get_selection ();
	my ($ret, $val);
	
	my @vals;
	# we need untranslated templates for this
	$this->question->template->i18n('');
	my @choices=$this->question->choices_split;
	$this->question->template->i18n(1);
	
	my $iter = $list_store->get_iter_first ();
	for (my $i=0; $i <= $#choices; $i++) {
		if ($list_selection->iter_is_selected ($iter)) {
			push @vals, $choices[$i];
		}
		$iter = $list_store->iter_next ($iter);
	}

	return join(', ', $this->order_values(@vals));
}

=head1 AUTHOR

Eric Gillespie <epg@debian.org>
Gustavo Noronha Silva <kov@debian.org>

=cut

1
