#!/usr/bin/perl -w

=head1 NAME

Debconf::FrontEnd::Text - legacy text frontend

=cut

package Debconf::FrontEnd::Text;
use strict;
use base qw(Debconf::FrontEnd::Readline);

=head1 DESCRIPTION

This file is here only for backwards compatability, so that things that try
to use the Text frontend continue to work. It was renamed to the Readline
frontend. Transition plan:

- woody will be released with the ReadLine frontend, and upgrades to woody
  will move away from the text frontend to it, automatically.
- woody+1, unstable: begin outputting a warning message when this frontend
  is used. Get everything that still uses it fixed
- woody+1, right before freeze: remove this file

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
