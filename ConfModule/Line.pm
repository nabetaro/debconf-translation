#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::ConfModule::Base - ConfModule that interfaces to the line based FrontEnd

=cut

=head1 DESCRIPTION

This is a ConfModule that interfaces to the line-at-a-time FrontEnd.

Currently, this is identical to the Base ConfModule.

=cut

package Debian::DebConf::ConfModule::Line;
use Debian::DebConf::ConfModule::Base;
use strict;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::ConfModule::Base);

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut


1
