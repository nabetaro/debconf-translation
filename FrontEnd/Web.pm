#!/usr/bin/perl -w
#
# FrontEnd that acts as a web server. It's worth noting that this doesn't
# worry about security at all, so it really isn't ready for use. It's a
# proof-of-concept only. In fact, it's probably the crappiest web server ever.
# It only accpets one client at a time as well..

package Debian::DebConf::FrontEnd::Web;
use Debian::DebConf::FrontEnd::Base;
use Debian::DebConf::Priority;
use IO::Socket;
use IO::Select;
use CGI;
use strict;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::FrontEnd::Base);

# Pass in the port to bind to, 8001 is default.
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless $proto->SUPER::new(@_), $class;
	$self->{port}=shift || 8001;
	$self->{formid}=0;

	# Bind to the port.
	$self->{server}=IO::Socket::INET->new(
		LocalPort => $self->{port},
		Proto => 'tcp',
		Listen => 1,
		Reuse => 1
	) || die "Can't bind to ".$self->{port}.": $!";

	return $self;
}

# This returns the client that is currently waiting for input. Of course,
# if there is no client, it waits for one to connect. As a side affect,
# when a client connects, this also we reads in any http commands it has 
# for us and puts them in the commands property.
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

# Forcibly close the current client's connection.
sub closeclient {
	my $this=shift;
	
	close $this->client;
	$this->client('');
}

# Just display something to a client.
sub showclient {
	my $this=shift;
	my $page=shift;

	my $client=$this->client;
	print $client $page;
}

# This is called when it's time to display questions. It calls each element to
# get the html to display for it, and bundles it all up into a web page which
# is displayed to the client. Then it gets a response from the client and
# parses it.
sub go {
	my $this=shift;

	# Each form sent out has a unique id.
	my $formid=$this->formid(1 + $this->formid);
	
	my $form="<html>\n<title>".$this->{'title'}."</title>\n<body>\n";
	$form.="<form><input type=hidden name=formid value=$formid>\n";
	my $id=0;
	my %idtoelt;
	foreach my $elt (@{$this->{elements}}) {
		next unless Debian::DebConf::Priority::high_enough($elt->priority);
		# Some elements may use helper functions in the frontend
		# so they need to know what frontend to use.
		$elt->frontend($this);
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

1
