#!/usr/bin/perl

=head1 NAME

Debconf::TmpFile - temporary file creator

=cut

package Debconf::TmpFile;
use strict;
use IO::File;
use Fcntl;

=head1 DESCRIPTION

This module helps debconf make safe temporary files. At least, I think
they're safe, if /tmp is not on NFS.

=head1 METHODS

=over 4

=item open

Open a temporary file for writing. Returns an open file descriptor.
Optionally a file extension may be passed to it.

=cut

my $filename;

sub open {
	my $fh; # will be autovivified
	my $ext=shift || '';
	do { $filename=POSIX::tmpnam().$ext }
	until sysopen($fh, $filename, O_WRONLY|O_TRUNC|O_CREAT|O_EXCL, 0600);
	return $fh;
}

=item filename

Returns the name of the last opened temp file.

=cut

sub filename {
	return $filename;
}

=item cleanup

Unlinks the last opened tempfile.

=cut

sub cleanup {
	unlink $filename;
}

=back

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
