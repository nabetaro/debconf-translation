#!/usr/bin/perl -w
#
# Pass this program a list of .pm files. It parses them (halfheartedly,
# it works on my code, may not on your code), and generates an inheritcance
# graph of the modules.
#
# Remember: I have a copy of this in debconf and a copy in stool. Keep them
# sync'd.

use strict;

my %kids;
my %iskid;
my %descs;

foreach my $file (@ARGV) {
	my $package='';
	my $desc='';
	my @isa=();
	open (IN,$file) || die "$file: $!";
	while (<IN>) {
		if (/package\s(\w+.*?);/) {
			$package=$1;
		}
		# Gag. This just looks for @ISA= lines and use base.
		if (/(?:use\s+base\s+|\@ISA\s*=\s*)(?:q(?:w|q)?(?:\(|{)|"|')(.*?)(?:}|\)|'|")/) {
			push @isa, split(/\s+/, $1);
		}
		if (/.*::.*\s+-\s+(.*)/) {
			$desc=$1;
		}
	}
	close IN;
	
	if ($package) {
		$descs{$package}=$desc;
		foreach (@isa) {
			$kids{$_}{$package}=1;
			$iskid{$package}=1;
		}
	}
}

my %seen;

# Print out one item.
sub printitem {
	my $text=shift;
	my $item=shift;
	print $text . (' ' x (40 - length $text));
	print $descs{$item} if exists $descs{$item};
	print "\n";
}

# Recursively print out tree structure.
sub printkids {
	my $parent=shift;
	my $spacer=shift;
	
	foreach my $kid (sort keys %{$kids{$parent}}) {
		next if $seen{$kid};
		$seen{$kid}=1;
		# Strip off text in name that comes from any common parents.
		$_=$kid;
		foreach my $p (split(/::/,$parent)) {
			s/^$p\:://;
			
		}
		printitem($spacer.$_, $kid);
		printkids($kid, "  $spacer");
	}
}

# Print all parents with thier kids under them.
# It's important to only print toplevel parents, which is why
# %iskid comes into play.
foreach my $parent (sort keys %kids) {
	next if $iskid{$parent};
	printitem($parent, $parent);
	printkids($parent, "  ");
}
