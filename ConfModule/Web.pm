#!/usr/bin/perl -w
#
# ConfModule that interfaces to the web FrontEnd.

package Debian::DebConf::ConfModule::Web;
use Debian::DebConf::ConfModule::Base;
use strict;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::ConfModule::Base);

# This module can backup.
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless $proto->SUPER::new(@_), $class;
	$self->{capb} = 'backup';
	return $self;					
}

1
