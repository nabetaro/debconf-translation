#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::ConfModule::Web - ConfModule that interfaces to the web FrontEnd

=cut

=head1 DESCRIPTION

This is a ConfModule that interfaces to the web FrontEnd.

Currently, this is identical to the Base ConfModule, except it has the
capability to backup, and so its capb property is set appropriatly.

=cut

package Debian::DebConf::ConfModule::Web;
use Debian::DebConf::ConfModule;
use strict;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::ConfModule);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless $proto->SUPER::new(@_), $class;
	$self->{capb} = 'backup';
	return $self;					
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
