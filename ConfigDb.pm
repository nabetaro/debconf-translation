#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::ConfigDb -- debian configuration database

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

package Debian::DebConf::ConfigDb;
use Debian::DebConf::Template;
use Debian::DebConf::Question;
use strict;
use vars qw($AUTOLOAD %templates %questions);

=head2 getquestion

Pass in the name of the question and this will return the specified question
object.

=cut

sub getquestion {
	return $questions{(shift)};
}

=head2 loadtemplatefile

Loads up a file containing templates (pass the filename to load). Creates
Template objects and corresponding Question objects. The second parameter is
the name of the owner of the created templates and questions.

=cut

sub loadtemplatefile {
	my $fn=shift;
	my $owner=shift;
	
	my $collect;
	open (TEMPLATE_IN, $fn) || die "$fn: $!";
	while (<TEMPLATE_IN>) {
		if ($_ ne "\n") {
			$collect.=$_;
		}
		if ($_ eq "\n" || eof TEMPLATE_IN) {
			# Have to be careful here to ensure that if a template
			# already exists in the db and we load it up, the
			# changes replace the old template without
			# instantiating a new template.
			my $template=Debian::DebConf::Template->new();
			$template->parse($collect);
			
			if ($templates{$template->template}) {
				# An old template with this name exists. Merge
				# all info from the new template into it.
				$template->merge($templates{$template->template});
			}
			else {
				$templates{$template->template}=$template;
			}

			# Make a question to go with this template.
			addquestion($template->template, $template->template,
				    $owner);

			$collect='';
		}
	}
	close TEMPLATE_IN;
	return 1;
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

	my $question=$questions{$name} || Debian::DebConf::Question->new;

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
	
	$questions{$name}->removeowner($owner);
	if ($questions{$name}->owners eq '') {
		my $template=$questions{$name}->template;
		# Does the template go away too?
		my $users=0;
		foreach my $question (keys %questions) {
			$users++ if $question->template eq $template;
		}
		
		if ($users == 0) {
			delete $templates{$template};
		}
		
		delete $questions{$name};
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
backend db in the spec that this ignores. Pass the filename to save to.

=cut

use Data::Dumper;
sub savedb {
	my $fn=shift;

	my $dumper=Data::Dumper->new([\%templates, \%questions],
		[qw{*templates *questions}]);
	$dumper->Indent(1);
	open (OUT, ">$fn") || die "$fn: $!";
	print OUT $dumper->Dump;
	print OUT "\n1;\n"; # Return a true value so require works.
	close OUT;
}

=head2 loaddb

Loads the current state from disk. Again, a quick hack. Pass the filename
to load.

=cut

sub loaddb {
	require shift;
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
