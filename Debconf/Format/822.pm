#!/usr/bin/perl -w

=head1 NAME

Debconf::Format::822 - RFC-822-ish output format

=cut

package Debconf::Format::822;
use strict;
use base 'Debconf::Format';

=head1 DESCRIPTION

This formats data in a vaguely RFC-822-ish way.

=cut

sub read {
	my $this=shift;
	my $fh=shift;
	
	my %ret=(
		owners => {},
		fields => {},
		variables => {},
		flags => {},
	);

	my $invars=0;
	my $line;
	while ($line = <$fh>) {
		chomp $line;
		last if $line eq ''; # blank line is our record delimiter

		# Process variables.
		if ($invars) {
			if ($line =~ /^\s/) {
				$line =~ s/^\s+//;
				my ($var, $value)=split(/\s*=\s*/, $line, 2);
				$value=~s/\\n/\n/g;
				$ret{variables}->{$var}=$value;
				next;
			}
			else {
				$invars=0;
			}
		}

		# Process the main structure.
		my ($key, $value)=split(/:\s*/, $line, 2);
		$key=lc($key);
		if ($key eq 'owners') {
			foreach my $owner (split(/,\s+/, $value)) {
				$ret{owners}->{$owner}=1;
			}
		}
		elsif ($key eq 'flags') {
			foreach my $flag (split(/,\s+/, $value)) {
				$ret{flags}->{$flag}='true';
			}
		}
		elsif ($key eq 'variables') {
			$invars=1;	
		}
		elsif (length $key) {
			$value=~s/\\n/\n/g;
			$ret{fields}->{$key}=$value;
		}
	}

	return \%ret;
}

sub write {
	my $this=shift;
	my $fh=shift;
	my %data=%{shift()};

	foreach my $field (sort keys %{$data{fields}}) {
		my $val=$data{fields}->{$field};
		$val=~s/\n/\\n/g;
		print $fh ucfirst($field).": $val\n";
	}
	if (keys %{$data{owners}}) {
		print $fh "Owners: ".join(", ", keys(%{$data{owners}}))."\n";
	}
	if (grep { $data{flags}->{$_} eq 'true' } keys %{$data{flags}}) {
		print $fh "Flags: ".join(", ",
			grep { $data{flags}->{$_} eq 'true' }
				sort keys(%{$data{flags}}))."\n";
	}
	if (keys %{$data{variables}}) {
		print $fh "Variables:\n";
		foreach my $var (sort keys %{$data{variables}}) {
			my $val=$data{variables}->{$var};
			$val=~s/\n/\\n/g;
			print $fh " $var = $val\n";
		}
	}
	print $fh "\n"; # end of record delimiter
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
