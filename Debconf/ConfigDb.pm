#!/usr/bin/perl -w

=head1 NAME

Debconf::ConfigDb - debian configuration database

=cut

=head1 DESCRIPTION

Debian configuration database. This is an interface to the actual
backend databases. It keeps track of Questions and Templates.
This is a simple perl module, not a full-fledged object. It's a bit of a
catchall, and perhaps the ugliest part of debconf.

It will probably need to be rewritten when we actually get a backend db.

=cut

=head1 METHODS

=cut

package Debconf::ConfigDb;
use Debconf::Template;
use Debconf::Question;
use strict;
use base qw(Exporter);
our @EXPORT_OK = qw(getquestion gettree isunder registertemplates
		addquestion disownquestion disownall
		savedb loaddb);
our %templates;
our %questions;

=head2 getquestion

Pass in the name of the question and this will return the specified question
object.

=cut

sub getquestion {
	return $questions{(shift)};
}

=head2 gettree

Pass in a string denoting the root of a tree of questions in the question 
hierarchy. All questions under that root will be returned.

=cut

sub gettree {
	my $root=shift;

	my @ret=();
	foreach my $name (keys %questions) {
		if ($name=~m:^\Q$root/\E:) {
			push @ret, $questions{$name};
		}
	}
	
	return @ret;
}

=head2 isunder

Pass in a string denoting the root of a tree of questions in the question
hierarchy, and a Question. If the Question is under that tree, a true value
is returned.

=cut

sub isunder {
	my $root=shift;
	my $name=shift->name;
	
	return $name=~m:^\Q$root/\E:;
}

=head2 registertemplates

Registers a set of templates into the database. Call this after loading up
and instantiating the templates. Registering the templates in the database
means other code can look them up, and means they will be saved. It also
causes questions to be created with the same names as each new template.

First pass the name of the owner of the templates and any questions that
will be created, and then any number of Templates.

=cut

sub registertemplates {
	my $owner=shift;
	foreach (@_) {
		# Have to be careful here to ensure that if a template
		# already exists in the db and we load it up, the changes
		# replace the old template without instantiating a new
		# template.
		if ($templates{$_->template}) {
			# An old template with this name exists. Clear it
			# and replace its data with the data from the new
			# template.
			$templates{$_->template}->clear;
			$templates{$_->template}->merge($_);
		}
		else {
			$templates{$_->template}=$_;
		}

		# Make a question to go with this template.
		addquestion($_->template, $_->template, $owner);
	}
}

=head2 addquestion

Create a Question and add it to the database. Pass the name of the template
the question will use, and the name to use for the question. Finally, pass
the name of the owner of the new question.

If a question by this name already exists, it will be modified to add the
new owner and to use the correct template.

=cut

sub addquestion {
	my $template=shift;
	my $name=shift;
	my $owner=shift;

	my $question=$questions{$name} || Debconf::Question->new;
	$question->name($name);
	$question->template($templates{$template});
	$question->addowner($owner);
	$questions{$name}=$question;
}

=head2 disownquestion

Give up ownership of a given question. Pass the name of the question and the
owner that is giving it up. When the number of owners reaches 0, the question
itself is removed. If the template the question used has no more questions
using it, it too is removed.

=cut

sub disownquestion {
	my $name=shift;
	my $owner=shift;
	
	return unless $questions{$name};
	
	$questions{$name}->removeowner($owner);
	if ($questions{$name}->owners eq '') {
		my $template=$questions{$name}->template;
		# Does the template go away too? Look at how many questions
		# use it.
		my $users=0;
		foreach my $question (keys %questions) {
			$users++ if $questions{$question}->template eq $template;
		}
		delete $questions{$name};

		# Only the current question uses it.
		if ($users == 1) {
			delete $templates{$template->template};
		}
	}
}

=head2 disownall

This runs disownquestion() on all Questions. Pass the owner.

=cut

sub disownall {
	my $owner=shift;
	
	foreach my $question (keys %questions) {
		disownquestion($question, $owner);
	}
}

=head2 savedb

Save the current state to disk. This is a quick hack, there is a whole
backend db in the spec that this ignores. Pass the directory to save to,
two files will be created in it.

=cut

use Data::Dumper;
sub savedb {
	my $dir=shift;

	my $dumper=Data::Dumper->new([\%questions], ['*questions']);
	my %seen;
	foreach (keys %templates) {
		$seen{"\$templates{'$_'}"}=$templates{$_};
	}
	$dumper->Seen({%seen});
	$dumper->Indent(1);
	open (OUT, ">$dir/debconf.new") || die "$dir/debconf.new: $!";
	print OUT $dumper->Dump;
	print OUT "\n1;\n"; # Return a true value so require works.
	close OUT;
	
	$dumper=Data::Dumper->new([\%templates],
		[qw{*templates}]);
	$dumper->Indent(1);
	open (OUT, ">$dir/templates.new") || die "$dir/templates.new: $!";
	print OUT $dumper->Dump;
	print OUT "\n1;\n"; # Return a true value so require works.
	close OUT;
	
	# Now atomically move the files into place.
	system 'mv', "-f", "$dir/templates.new", "$dir/templates.db";
	system 'mv', "-f", "$dir/debconf.new", "$dir/debconf.db";
}

=head2 loaddb

Loads the current state from disk. Again, a quick hack. Pass the directory
the database is in.

=cut

sub loaddb {
	my $dir=shift;

	if (-e "$dir/templates.db") {
		eval qq{require "$dir/templates.db"};
	}

	if (-e "$dir/debconf.db") {
		eval qq{require "$dir/debconf.db"};
	}

	# This code is here to handle the transition from the isdefault
	# flag to the seen flag.
	foreach (values %questions) {
		if (exists $_->{flag_isdefault}) {
			$_->flag_seen($_->{flag_isdefault} eq "true" ? "false" : "true");
			delete $_->{flag_isdefault};
		}
	}
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
