#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Slang::Internal - Base internal element.

=cut

=head1 DESCRIPTION

The Slang FrontEnd needs to have elements onscreen that are not bound to a
Question. This is the base class for such elements.

=cut

=head1 METHODS

=cut

package Debian::DebConf::Element::Slang::Internal;
use strict;
use Debian::DebConf::Element::Slang; # perlbug
use base qw(Debian::DebConf::Element::Slang);

sub value {
	die "Attempted to access value of internal slang element.";
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
