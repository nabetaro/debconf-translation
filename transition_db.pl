#!/usr/bin/perl -w
# Disgusting hack to transition from debconf's even more disgusting old
# database to its nice bright sparkling new one.
use strict;
use Debconf::Db;
use Debconf::Question;
use Debconf::Template::Persistent;

my $dir = shift || '/var/lib/debconf';

our %questions;
our %templates;

# Load order is important.
foreach my $thing (qw(templates debconf)) {
	if (-e "$dir/$thing.db") {
		eval qq{require "$dir/$thing.db"};
		print STDERR $@ if $@;
	}
	else {
		print STDERR "Skipping $dir/$thing.db: DNE\n";
	}
}

# Now make new Question objects for all the questions, pulling out
# Templates as need be, and registering them as owners of the templates.
# Kill empty owner fields as I go, they are a vestiage of an old bug.
foreach my $item (keys %questions) {
	my @owners=grep { $_ ne '' } keys %{$questions{$item}->{owners}};
	next unless @owners;
	
	# Make sure that the template used by this item exists.
	my $tname=$questions{$item}->{template};
	my $template=Debconf::Template::Persistent->get($tname);
	unless (defined $template) {
		# Template does not exist yet, so we have to pull it out of
		# the %templates hash.
		$template=Debconf::Template::Persistent->new($tname, $item);
		# Simply copy every field into it.
		foreach my $field (%{$templates{$tname}}) {
			$template->$field($templates{$tname}->{$field});
		}
	}
	
	my $question=Debconf::Question->new($item, pop @owners);
	$question->addowner($_) foreach @owners;
	# Copy over all significant values.
	# This old flag morphes into the seen flag, inverting meaning.
	if (exists $questions{$item}->{flag_isdefault}) {
		if ($questions{$item}->{flag_isdefault} eq 'false') {
		    	$question->flag('seen', 'true');
		}
		delete $questions{$item}->{flag_isdefault};
	}
	# All other flags. (ignoring for now, as there should be none)
	#foreach my $flag (grep /^flag_/, keys %{$questions{$item}}) {
	#	if ($questions{$item}->{$flag} eq 'true') {
	#		$flag=~s/^flag_//;
	#		$question->flag($flag, 'true');
	#	}
	#}
	# All variables.
	foreach my $var (keys %{$questions{$item}->{variables}}) {
		$question->variable($var,
			$questions{$item}->{variables}->{$var});
	}
	if (exists $questions{$item}->{value} 
		and defined $questions{$item}->{value}) {
		$question->value($questions{$item}->{value});
	}
	# And finally, set its template.
	$question->template($questions{$item}->{template});
}

Debconf::Db->save;
