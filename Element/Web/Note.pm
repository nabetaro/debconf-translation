#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Web::Note - A paragraph on a form

=cut

=head1 DESCRIPTION

This element handles a paragraph of text on a web form. It is identical to
Debian::DebConf::Element::Web::Text.

=cut

=head1 METHODS

=cut

package Debian::DebConf::Element::Web::Note;
use strict;
use Debian::DebConf::Element::Web::Text; # perlbug
use base qw(Debian::DebConf::Element::Web::Text);

1
