#!/usr/bin/perl -w

=head1 NAME

Debconf::FrontEnd::Noninteractive - non-interactive FrontEnd

=cut

package Debconf::FrontEnd::Noninteractive;
use strict;
use base qw(Debconf::FrontEnd);

=head1 DESCRIPTION

This FrontEnd is completly non-interactive.

=cut

=item init

tty not needed

=cut

sub init { 
        my $this=shift;

        $this->SUPER::init(@_);

        $this->need_tty(0);
}


1
