#!/usr/bin/perl -w

=head1 NAME

Debconf::DbDriver::Debug - debug db requests

=cut

package Debconf::DbDriver::Debug;
use strict;
use Debconf::Log qw{:all};
use base 'Debconf::DbDriver';

=head1 DESCRIPTION

This driver is useful only for debugging other drivers. It makes each
method call output rather verbose debugging output.

=cut

=head1 FIELDS

=over 4

=item db

All requests are passed to this database, with logging.

=back

=cut

use fields qw(db);

=head1 METHODS

=head2 init

Validate the db field.

=cut

sub init {
	my $this=shift;

	# Handle value from config file.
	if (! ref $this->{db}) {
		$this->{db}=$this->driver($this->{db});
		unless (defined $this->{db}) {
			$this->error("could not find db");
		}
	}
}

# Ignore.
sub DESTROY {}

# All other methods just pass on to db with logging.
sub AUTOLOAD {
	my $this=shift;
	(my $command = our $AUTOLOAD) =~ s/.*://;

	debug "db $this->{name}" => "running $command(".join(",", map { "'$_'" } @_).") ..";
	if (wantarray) {
		my @ret=$this->{db}->$command(@_);
		debug "db $this->{name}" => "$command returned (".join(", ", @ret).")";
		return @ret if @ret;
	}
	else {
		my $ret=$this->{db}->$command(@_);
		if (defined $ret) {
			debug "db $this->{name}" => "$command returned \'$ret\'";
			return $ret;
		}
		else  {
			debug "db $this->{name}" => "$command returned undef";
		}
	}
	return; # failure
}

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
