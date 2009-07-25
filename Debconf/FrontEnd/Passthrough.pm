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
use Debconf::Element::Select;
use Debconf::Element::Multiselect;
use Debconf::Log qw(:all);
use Debconf::Encoding;
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

	binmode $this->{readfh}, ":utf8";
	binmode $this->{writefh}, ":utf8";

	$this->{readfh}->autoflush(1);
	$this->{writefh}->autoflush(1);
	
	# Note: SUPER init is not called, since it does several things
	# inappropriate for passthrough frontends, including clearing the capb.
	$this->elements([]);
	$this->interactive(1);
	$this->need_tty(0);
}

=head2 talk

Communicates with the UI agent. Joins all parameters together to create a
command, sends it to the agent, and reads and processes its reply.

=cut

sub talk {
	my $this=shift;
	my $command=join(' ', map { Debconf::Encoding::to_Unicode($_) } @_);
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
	$val = '' unless defined $val;
	$val = Debconf::Encoding::convert("UTF-8", $val);

	return ($tag, $val) if wantarray;
	return $tag;
}

=head2 makeelement

This frontend doesn't really make use of Elements to interact with the user,
so it uses generic Elements as placeholders (except for select and
multiselect Elements for which it needs translation methods). This method
simply makes one.

=cut

sub makeelement
{
	my $this=shift;
	my $question=shift;

	my $type=$question->type;
	if ($type eq "select" || $type eq "multiselect") {
		$type=ucfirst($type);
		return "Debconf::Element::$type"->new(question => $question);
	} else {
		return Debconf::Element->new(question => $question);
	}
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
	return $this->{title} unless @_;
	my $title = shift;

	$this->{title} = $title;
	$this->talk('TITLE', $title);
}

=head2 settitle

Pass title question name along to the UI agent, along with necessary data
about it.

=cut

sub settitle
{
	my $this = shift;
	my $question = shift;

	$this->{title} = $question->description;

	my $tag = $question->template->template;
	my $type = $question->template->type;
	my $desc = $question->description;
	my $extdesc = $question->extended_description;

	$this->talk('DATA', $tag, 'type', $type);

	if ($desc) {
		$desc =~ s/\n/\\n/g;
		$this->talk('DATA', $tag, 'description', $desc);
	}

	if ($extdesc) {
		$extdesc =~ s/\n/\\n/g;
		$this->talk('DATA', $tag, 'extended_description', $extdesc);
	}

	$this->talk('SETTITLE', $tag);
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
		my $default;
		if ($type eq 'select') {
			$default = $element->translate_default;
		} elsif ($type eq 'multiselect') {
			$default = join ', ', $element->translate_default;
		} else {
			$default = $question->value;
		}

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
			my $type = $element->question->template->type;

			my ($ret, $val)=$this->talk('GET', $tag);
			if ($ret eq "0") {
				if ($type eq 'select') {
					$element->value($element->translate_to_C($val));
				} elsif ($type eq 'multiselect') {
					$element->value(join(', ', map { $element->translate_to_C($_) } split(', ', $val)));
				} else {
					$element->value($val);
				}
				debug developer => "Got \"$val\" for $tag";
			}
		} else {
			# "show" noninteractive elements, which don't need
			# to pass through, but may do something when shown.
			$element->show;
		}
	}

	return 1;
}

=head2 progress_data

Send necessary data about any progress bar template to the UI agent.

=cut

sub progress_data {
	my $this=shift;
	my $question=shift;

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
		$this->talk('DATA', $tag, 'extended_description', $extdesc);
	}
}

sub progress_start {
	my $this=shift;

	$this->progress_data($_[2]);
	return $this->talk('PROGRESS', 'START', $_[0], $_[1], $_[2]->template->template);
}

sub progress_set {
	my $this=shift;

	return (scalar($this->talk('PROGRESS', 'SET', $_[0])) ne "30");
}

sub progress_step {
	my $this=shift;

	return (scalar($this->talk('PROGRESS', 'STEP', $_[0])) ne "30");
}

sub progress_info {
	my $this=shift;

	$this->progress_data($_[0]);
	return (scalar($this->talk('PROGRESS', 'INFO', $_[0]->template->template)) ne "30");
}

sub progress_stop {
	my $this=shift;

	return $this->talk('PROGRESS', 'STOP');
}

=back

=head1 AUTHOR

Randolph Chung <tausq@debian.org>

=cut

1

