#!/usr/bin/perl -w

=head NAME

Debian::DebConf::FrontEnd::Passthrough - Passthrough meta-frontend for DebConf

=cut

package Debian::DebConf::FrontEnd::Passthrough;
use strict;
use Carp;
use IO::Socket;
use Debian::DebConf::FrontEnd;
use Debian::DebConf::Log qw(:all);
use base qw(Debian::DebConf::FrontEnd);

my $DEBCONFPIPE = $ENV{DEBCONF_PIPE} || '/var/lib/debconf/debconf.ipc';

=head1 DESCRIPTION

This is a IPC pass-through frontend for DebConf. It is meant to enable 
integration of DebConf frontend components with installation systems.

The basic idea of this frontend is to reply messages between the
ConfModule and an arbitrary UI agent. For the most part, messages are
simply relayed back and forth unchanged.

=head1 METHODS

=over 4

=item init

Set up the pipe to the UI agent.

=cut

sub init {
	my $this=shift;
	my $thepipe;

	$this->{thepipe} = new IO::Socket::UNIX->new(
		Type => SOCK_STREAM,
		Peer => $DEBCONFPIPE
	) || carp "Cannot connect to $DEBCONFPIPE: $!";

	$this->{thepipe}->autoflush(1);
	
	$this->SUPER::init(@_);
	$this->interactive(1);
}

=head2 shutdown

The the UI agent know we're shutting down.

=cut

sub shutdown {
	my $this=shift;
	my $fh = $this->{thepipe} || carp "Broken pipe";
	debug developer => "Sending done signal";

	print $fh "done\n";
	$fh->flush;
}

=head2 makeelement

This frontend doesn't really make use of Elements to interact with the user,
so it uses generic Elements as placeholders. This method simply makes
one.

=cut

sub makeelement
{
	my $this=shift;
	my $question=shift;
	my $element=Debian::DebConf::Element->new(question => $question);
	return if ! ref $element;
	return $element;
}

=head2 capb_backup

Pass capability information along to the UI agent.

=cut

sub capb_backup
{
	my $this=shift;
	my $val = shift;
	my $fh = $this->{thepipe} || carp "Broken pipe";

	$this->{capb_backup} = $val;
	if ($val) {
		print $fh "capb backup\n";
	} else {
		print $fh "capb nobackup\n";
	}
}

=head2 title

Pass title along to the UI agent.

=cut

sub title
{
	my $this = shift;
	my $title = shift;
	my $fh = $this->{thepipe} || carp "Broken pipe";

	$this->{title} = $title;

	print $fh "title $title\n";
}

=head2 go

Asks the UI agent to display all pending questions, first using the special 
data command to tell it necessary data about them. Then read answers from
the UI agent.

=cut

sub go {
	my $this = shift;
	my $fh = $this->{thepipe} || carp "Broken pipe";
	my %answers;
	my $datasent = 0;

	foreach my $element (@{$this->elements}) {
		$datasent++;
		my $question = $element->question;
		my $tag = $question->template->template;
		my $type = $question->template->type;
		my $desc = $question->description;
		my $extdesc = $question->extended_description;
		my $choices = $question->choices;
		my $default = $question->value;

		$desc =~ s/\n/\\n/g if (defined($extdesc));
		$extdesc =~ s/\n/\\n/g if (defined($extdesc));
		$choices =~ s/\n/\\n/g if (defined($choices));

		print $fh "data $tag description $desc\n" if ($desc);
		print $fh "data $tag extended-description $extdesc\n" if ($extdesc);
		print $fh "data $tag choices $choices\n" if ($choices);
		print $fh "input $tag $type $default\n";
	}

	if ($datasent > 0) {
		print $fh "go\n";
		$fh->flush;

		# loop while waiting for data
		while (<$fh>) {
			chomp;
			last if (!$_);
			my ($tag, $data) = split(/ +/, $_, 2);
			if ($tag eq "30") {
				if ($this->capb_backup) {
					$this->clear;
					return;
				}
			}
			last if ($tag eq "0");
			$answers{$tag} = $data;
		}
	}

	# Assign the answers
	foreach my $element (@{$this->elements}) {
		my $tag = $element->question->template->template;
		if (defined($answers{$tag})) {
			$element->question->value($answers{$tag});
			$element->question->flag_isdefault('false');
			debug developer => "Setting value of $tag to ".$answers{$tag};
		}
	}
	
	$this->clear;
	return 1;
}
1

