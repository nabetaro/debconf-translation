#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Slang::Boolean - check box widget

=cut
                
=head1 DESCRIPTION

This is a check box widget.

=cut

package Debian::DebConf::Element::Slang::Boolean;
use strict;
use Term::Stool::CheckBox;
use Debian::DebConf::Element; # perlbug
use base qw(Debian::DebConf::Element);

sub makewidget {
	my $this=shift;
	my $yoffset=shift;

	$this->widget(Term::Stool::CheckBox->new(
		checked => ($this->question->value eq 'true') ? 1 : 0,
	));
}

=head2 resize

This is called when the widget is resized. The check box always must go on
the same line as the description, on its left hand side.

=cut

sub resize {
	my $this=shift;
	my $widget=$this->widget;
	my $description=$widget->description;
	my $maxwidth=$widget->container->width - 4;

	$widget->sameline(1);
	$widget->xoffset(1);
	$description->xoffset(1 + $widget->width + 1);
	$description->width($widget->container->width - 4 -
		$description->xoffset + 1);
}

sub value {
	my $this=shift;

	my $ret='false';
	$ret='true' if $this->widget->checked;
	return $ret;
}

1
