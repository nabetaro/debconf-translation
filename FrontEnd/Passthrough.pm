#!/usr/bin/perl -w

=head NAME

Debian::DebConf::FrontEnd::Passthrough - pass-through meta-frontend for DebConf

=cut

package Debian::DebConf::FrontEnd::Passthrough;
use strict;
use Carp;
use IO::Socket;
use Debian::DebConf::FrontEnd;
use Debian::DebConf::Element;
use Debian::DebConf::Log qw(:all);
use base qw(Debian::DebConf::FrontEnd);

my $DEBCONFPIPE = $ENV{DEBCONF_PIPE} || '/var/lib/debconf/debconf.ipc';

=head1 DESCRIPTION

This is a IPC pass-through frontend for DebConf. It is meant to enable 
integration of DebConf frontend components with installation systems.

The basic idea of this frontend is to replay messages between the
ConfModule and an arbitrary UI agent. For the most part, messages are
simply relayed back and forth unchanged.

=head1 METHODS

=over 4

=item init

Set up the pipe to the UI agent and other housekeeping chores.

=cut

sub init {
	my $this=shift;

	$this->{thepipe} = IO::Socket::UNIX->new(
		Type => SOCK_STREAM,
		Peer => $DEBCONFPIPE
	) || carp "Cannot connect to $DEBCONFPIPE: $!";

	$this->{thepipe}->autoflush(1);
	
	$this->SUPER::init(@_);
	$this->interactive(1);
}

=head2 talk

Communicates with the UI agent. Joins all parameters together to create a
command, sends it to the agent, and reads and processes its reply.

=cut

sub talk {
	my $this=shift;
	my $command=join(' ', @_);
	my $reply;
	
	my $fh = $this->{thepipe} || carp "Broken pipe";
	
	debug developer => "----> $command";
	print $fh $command."\n";
	$fh->flush;
	$reply = <$fh>;
	chomp($reply);
	debug developer => "<---- $reply";
	my ($tag, $val) = split(' ', $reply, 2);

	return ($tag, $val) if wantarray;
	return $tag;
}

=head2 shutdown

Let the UI agent know we're shutting down.

=cut

sub shutdown {
	my $this=shift;
	
	debug developer => "Sending done signal";
	$this->talk('STOP');
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
	return unless ref $element; # Why is this here?
	return $element;
}

=head2 capb_backup

Pass capability information along to the UI agent.

=cut

sub capb_backup
{
	my $this=shift;
	my $val = shift;

	$this->{capb_backup} = $val;
	$this->talk('CAPB', 'backup') if $val;
}

=head2 capb

Gets UI agent capabilities.

=cut

sub capb
{
	my $this=shift;
	my $ret;
	return $this->{capb} if exists $this->{capb};

	($ret, $this->{capb}) = $this->talk('CAPB');
	return $this->{capb} if $ret eq '0';
}

=head2 title

Pass title along to the UI agent.

=cut

sub title
{
	my $this = shift;
	my $title = shift;

	$this->{title} = $title;
	$this->talk('TITLE', $title);
}

=head2 go

Asks the UI agent to display all pending questions, first using the special 
data command to tell it necessary data about them. Then read answers from
the UI agent.

=cut

sub go {
	my $this = shift;

	foreach my $element (@{$this->elements}) {
		# TODO: I think only elements with flag_isdefault = true
		#       should be shown here. -JEH
		my $question = $element->question;
		my $tag = $question->template->template;
		my $type = $question->template->type;
		my $desc = $question->description;
		my $extdesc = $question->extended_description;
		my $default = $question->value;

		if ($desc) {
			$desc =~ s/\n/\\n/g;
			$this->talk('DATA', $tag, 'description', $desc);
		}

		if ($extdesc) {
			$extdesc =~ s/\n/\\n/g;
			$this->talk('DATA', $tag, 'extended-description',
			            $extdesc);
		}

		if ($type eq "select") {
			my $choices = $question->choices;
			$choices =~ s/\n/\\n/g if ($choices);
			$this->talk('DATA', $tag, 'choices', $choices);
		}

		$this->talk('SET', $tag, $default) if $default ne '';
		# TODO: This INPUT command doesn't meet the protocol spec.
		#       It should pass the priority and the question name,
		#       not the type. I suppose type should be passed by
		#       a DATA command.
		$this->talk('INPUT', $tag, $type);
	}

	# Tell the agent to display the question(s), and check
	# for a back button.
	if ((scalar($this->talk('GO')) eq "30") && $this->{capb_backup}) {
		$this->clear;
		return;
	}
	
	# Retrieve the answers.
	foreach my $element (@{$this->elements}) {
		my $tag = $element->question->template->template;

		my ($ret, $val)=$this->talk('GET', $tag);
		if ($ret eq "0") {
			$element->question->value($val);
			$element->question->flag_isdefault('false');
			debug developer => "Setting value of $tag to $val";
		}
	}
	
	$this->clear;
	return 1;
}

=back

=head1 AUTHOR

Randolph Chung <tausq@debian.org>

=cut

1

