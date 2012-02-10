#!/usr/bin/perl

=head1 NAME

Debconf::Path - path searching

=cut

package Debconf::Path;
use strict;
use File::Spec;

=head1 DESCRIPTION

This module helps debconf test whether programs are available on the
executable search path.

=head1 METHODS

=over 4

=item find

Return true if and only if the given program exists on the path.

=cut

sub find {
	my $program=shift;
	my @path=File::Spec->path();
	for my $dir (@path) {
		my $file=File::Spec->catfile($dir, $program);
		return 1 if -x $file;
	}
	return '';
}

=back

=head1 AUTHOR

Colin Watson <cjwatson@debian.org>

=cut

1
