#!/usr/bin/perl -w

=head1 NAME

DebConf::FrontEnd::Web - web FrontEnd

=cut

=head1 DESCRIPTION

This is a FrontEnd that acts as a small, stupid web server. It's worth noting
that this doesn't worry about security at all, so it really isn't ready for
use. It's a proof-of-concept only. In fact, it's probably the crappiest web
server ever. It only accpets one client at a time!

=cut

=head1 METHODS

=cut

package Debian::DebConf::FrontEnd::Web;
use Debian::DebConf::FrontEnd::Base;
use Debian::DebConf::Element::Web::String;
use Debian::DebConf::Element::Web::Boolean;
use Debian::DebConf::Element::Web::Select;
use Debian::DebConf::Element::Web::Text;
use Debian::DebConf::Element::Web::Note;
use Debian::DebConf::Priority;
use IO::Socket;
use IO::Select;
use CGI;
use strict;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::FrontEnd::Base);

=head2 new

Creates and returns an object of this class. The object binds to port 8001, or
any port number passed as a parameter to this function.

=cut

# Pass in the port to bind to, 8001 is default.
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless $proto->SUPER::new(@_), $class;
	$self->{port}=shift || 8001;
	$self->{formid}=0;
	$self->{interactive}=1;

	# Bind to the port.
	$self->{server}=IO::Socket::INET->new(
		LocalPort => $self->{port},
		Proto => 'tcp',
		Listen => 1,
		Reuse => 1
	) || die "Can't bind to ".$self->{port}.": $!";

	return $self;
}

=head2 makeelement

This overrides the method in the Base FrontEnd, and creates Elements in the
Element::Web class. Each data type has a different Element created for it.

=cut

sub makeelement {
	my $this=shift;
	my $question=shift;

	# The type of Element we create depends on the input type of the
	# question.
	my $type=$question->template->type;
	my $elt;
	if ($type eq 'string') {
		$elt=Debian::DebConf::Element::Web::String->new;
	}
	elsif ($type eq 'boolean') {
		$elt=Debian::DebConf::Element::Web::Boolean->new;
	}
	elsif ($type eq 'select') {
		$elt=Debian::DebConf::Element::Web::Select->new;
	}
	elsif ($type eq 'text') {
		$elt=Debian::DebConf::Element::Web::Text->new;
	}
	elsif ($type eq 'note') {
		$elt=Debian::DebConf::Element::Web::Note->new;
	}
	else {
		die "Unknown type of element: \"$type\"";
	}
	
	$elt->question($question);
	# Some elements need a handle to their FrontEnd.
	$elt->frontend($this);

	return $elt;
}	

=head2 client

This method ensures that a client is connected to the web server and waiting for
input. If there is no client, it blocks until one connects. As a side affect, when
a client connects, this also reads in any HTTP commands it has for us and puts them
in the commands property.

=cut

sub client {
	my $this=shift;
	
	$this->{'client'}=shift if @_;
	return $this->{'client'} if $this->{'client'};

	my $select=IO::Select->new($this->server);
	1 while ! $select->can_read(1);
	my $client=$this->server->accept;
	my $commands='';
	while (<$client>) {
		last if $_ eq "\r\n";
		$commands.=$_;
	}
	$this->commands($commands);
	$this->{'client'}=$client;
}

=head2 closeclient

Forcibly close the current client's connection to the web server.

=cut

sub closeclient {
	my $this=shift;
	
	close $this->client;
	$this->client('');
}

=head2 showclient

Displays the passed text to the client. Can be called multiple times to build up
a page.

=cut

sub showclient {
	my $this=shift;
	my $page=shift;

	my $client=$this->client;
	print $client $page;
}

=head2 go

This overrides to go method in the Base FrontEnd. It
goes through each pending Element and asks it to return the html that
corresponds to that Element. It bundles all the html together into a
web page and displays the web page to the client. Then it waits for the
client to fill out the form, parses the client's response and uses that to
set values on the Elements.

=cut

sub go {
	my $this=shift;

	return unless @{$this->{elements}};

	# Each form sent out has a unique id.
	my $formid=$this->formid(1 + $this->formid);
	
	my $form="<html>\n<title>".$this->{'title'}."</title>\n<body>\n";
	$form.="<form><input type=hidden name=formid value=$formid>\n";
	my $id=0;
	my %idtoelt;
	foreach my $elt (@{$this->{elements}}) {
		# Each element has a unique id that it'll use on the form.
		$idtoelt{$id}=$elt;
		$elt->id($id++);
		$form.=$elt->show;
		$form.="<hr>\n";
	}
	
	$this->{elements}=[];
	$form.="<p>\n";
	# Should the back button be displayed?
	if ($this->capb_backup) {
		$form.="<input type=submit value=Back name=back>\n";
	}
	$form.="<input type=submit value=Next>\n";
	$form.="</form>\n</body>\n</html>\n";

	my $query;
	# We'll loop here until we get a valid response from a client.
	do {
		$this->showclient($form);
	
		# Now get the next connection to us, which causes any http
		# commands to be read.
		$this->closeclient;
		$this->client;
		
		# Now parse the http commands and get the query string out
		# of it.
		my @get=grep { /^GET / } split(/\r\n/, $this->commands);
		my $get=shift @get;
		my ($qs)=$get=~m/^GET\s+.*?\?(.*?)(?:\s+.*)?$/;
	
		# Now parse the query string.
		$query=CGI->new($qs);
	} until ($query->param('formid') eq $formid);

	# Did they hit the back button? If so, ignore their input and inform
	# the ConfModule of this.
	if ($this->capb_backup && $query->param('back') ne '') {
		return 'back';
	}

	# Now it's just a matter of matching up the element id's with values
	# from the form, and passing the values from the form into the
	# elements, for them to deal with.
	foreach my $id ($query->param) {
		next unless $idtoelt{$id};
		
		$idtoelt{$id}->set($query->param($id));
	}
	return '';
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
