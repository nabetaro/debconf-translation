#!/usr/bin/perl -w

=head NAME

Debconf::FrontEnd::Passthrough - pass-through meta-frontend for Debconf

=cut

package Debconf::FrontEnd::Passthrough;
use strict;
use Carp;
use IO::Socket;
use IO::Handle;
use Debconf::FrontEnd;
use Debconf::Element;
use Debconf::Log qw(:all);
use base qw(Debconf::FrontEnd);

my ($READFD, $WRITEFD, $SOCKET);
if (defined $ENV{DEBCONF_PIPE}) {
        $SOCKET = $ENV{DEBCONF_PIPE};
} elsif (defined $ENV{DEBCONF_READFD} && defined $ENV{DEBCONF_WRITEFD}) {
        $READFD = $ENV{DEBCONF_READFD};
        $WRITEFD = $ENV{DEBCONF_WRITEFD};
} else {
        die "Neither DEBCONF_PIPE nor DEBCONF_READFD and DEBCONF_WRITEFD were set\n";
}

=head1 DESCRIPTION

This is a IPC pass-through frontend for Debconf. It is meant to enable 
integration of Debconf frontend components with installation systems.

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

        if (defined $SOCKET) {
                $this->{readfh} = $this->{writefh} = IO::Socket::UNIX->new(
		        Type => SOCK_STREAM,
		        Peer => $SOCKET
	        ) || croak "Cannot connect to $SOCKET: $!";
        } else {
                $this->{readfh} = IO::Handle->new_from_fd(int($READFD), "r") || croak "Failed to open fd $READFD: $!";
                $this->{writefh} = IO::Handle->new_from_fd(int($WRITEFD), "w") || croak "Failed to open fd $WRITEFD: $!";
        }

	$this->{readfh}->autoflush(1);
	$this->{writefh}->autoflush(1);
	
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
	
	my $readfh = $this->{readfh} || croak "Broken pipe";
	my $writefh = $this->{writefh} || croak "Broken pipe";
	
	debug developer => "----> $command";
	print $writefh $command."\n";
	$writefh->flush;
	$reply = <$readfh>;
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
	
	return Debconf::Element->new(question => $question);
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

	my @elements=grep $_->visible, @{$this->elements};
	foreach my $element (@elements) {
		my $question = $element->question;
		my $tag = $question->template->template;
		my $type = $question->template->type;
		my $desc = $question->description;
		my $extdesc = $question->extended_description;
		my $default = $question->value;

                $this->talk('DATA', $tag, 'type', $type);

		if ($desc) {
			$desc =~ s/\n/\\n/g;
			$this->talk('DATA', $tag, 'description', $desc);
		}

		if ($extdesc) {
			$extdesc =~ s/\n/\\n/g;
			$this->talk('DATA', $tag, 'extended_description',
			            $extdesc);
		}

		if ($type eq "select" || $type eq "multiselect") {
			my $choices = $question->choices;
			$choices =~ s/\n/\\n/g if ($choices);
			$this->talk('DATA', $tag, 'choices', $choices);
		}

		$this->talk('SET', $tag, $default) if $default ne '';

		my @vars=$Debconf::Db::config->variables($question->{name});
		for my $var (@vars) {
			my $val=$Debconf::Db::config->getvariable($question->{name}, $var);
			$val='' unless defined $val;
			$this->talk('SUBST', $tag, $var, $val);
		}

		$this->talk('INPUT', $question->priority, $tag);
	}

	# Tell the agent to display the question(s), and check
	# for a back button.
	if (@elements && (scalar($this->talk('GO')) eq "30") && $this->{capb_backup}) {
		return;
	}
	
	# Retrieve the answers.
	foreach my $element (@{$this->elements}) {
		if ($element->visible) {
			my $tag = $element->question->template->template;

			my ($ret, $val)=$this->talk('GET', $tag);
			if ($ret eq "0") {
				$element->value($val);
				debug developer => "Got \"$val\" for $tag";
			}
		} else {
			my $default='';
			$default=$element->question->value if defined $element->question->value;
			$element->value($default);
		}
	}

	return 1;
}

=head2 progress

Send necessary data about any progress bar template to the UI agent, and
then ask it to display the progress bar changes.

=cut

sub progress {
	my $this=shift;
	my $subcommand=shift;
	my $question=shift;

	if (defined $question) {
		my $tag=$question->template->template;
		my $type=$question->template->type;
		my $desc=$question->description;
		my $extdesc=$question->extended_description;

		$this->talk('DATA', $tag, 'type', $type);

		if ($desc) {
			$desc =~ s/\n/\\n/g;
			$this->talk('DATA', $tag, 'description', $desc);
		}

		if ($extdesc) {
			$extdesc =~ s/\n/\\n/g;
			$this->talk('DATA', $tag, 'extended_description',
			            $extdesc);
		}
	}

	return $this->talk('PROGRESS', $subcommand, @_);
}

sub progress_start {
	my $this=shift;

	$this->progress('START', $_[2], @_);
}

sub progress_set {
	my $this=shift;

	$this->progress('SET', undef, @_);
}

sub progress_step {
	my $this=shift;

	$this->progress('STEP', undef, @_);
}

sub progress_info {
	my $this=shift;

	$this->progress('INFO', $_[0], @_);
}

sub progress_stop {
	my $this=shift;

	$this->progress('STOP', undef);
}

=back

=head1 AUTHOR

Randolph Chung <tausq@debian.org>

=cut

1

