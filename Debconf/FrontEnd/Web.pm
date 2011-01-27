#!/usr/bin/perl -w

=head1 NAME

Debconf::FrontEnd::Web - web FrontEnd

=cut

package Debconf::FrontEnd::Web;
use IO::Socket;
use IO::Select;
use CGI;
use strict;
use Debconf::Gettext;
use base qw(Debconf::FrontEnd);

=head1 DESCRIPTION

This is a FrontEnd that acts as a small, stupid web server. It is worth noting
that this doesn't worry about security at all, so it really isn't ready for
use. It's a proof-of-concept only. In fact, it's probably the crappiest web
server ever. It only accepts one client at a time!

=head1 FIELDS

=over 4

=item port

The port to bind to.

=cut

=back

=head1 METHODS

=over 4

=item init

Bind to the port.

=cut

sub init {
	my $this=shift;

	$this->SUPER::init(@_);
	
	$this->port(8001) unless defined $this->port;
	$this->formid(0);
	$this->interactive(1);
	$this->capb('backup');
	$this->need_tty(0);

	# Bind to the port.
	$this->server(IO::Socket::INET->new(
		LocalPort => $this->port,
		Proto => 'tcp',
		Listen => 1,
		Reuse => 1,
		LocalAddr => '127.0.0.1',
	)) || die "Can't bind to ".$this->port.": $!";

	print STDERR sprintf(gettext("Note: Debconf is running in web mode. Go to http://localhost:%i/"),$this->port)."\n";
}

=item client

This method ensures that a client is connected to the web server and waiting for
input. If there is no client, it blocks until one connects. As a side affect, when
a client connects, this also reads in any HTTP commands it has for us and puts them
in the commands field.

=cut

sub client {
	my $this=shift;
	
	$this->{client}=shift if @_;
	return $this->{client} if $this->{client};

	my $select=IO::Select->new($this->server);
	1 while ! $select->can_read(1);
	my $client=$this->server->accept;
	my $commands='';
	while (<$client>) {
		last if $_ eq "\r\n";
		$commands.=$_;
	}
	$this->commands($commands);
	$this->{client}=$client;
}

=item closeclient

Forcibly close the current client's connection to the web server.

=cut

sub closeclient {
	my $this=shift;
	
	close $this->client;
	$this->client('');
}

=item showclient

Displays the passed text to the client. Can be called multiple times to 
build up a page.

=cut

sub showclient {
	my $this=shift;
	my $page=shift;

	my $client=$this->client;
	print $client $page;
}

=item go

This overrides to go method in the parent FrontEnd. It goes through each
pending Element and asks it to return the html that corresponds to that
Element. It bundles all the html together into a web page and displays the
web page to the client. Then it waits for the client to fill out the form,
parses the client's response and uses that to set values in the database.

=cut

sub go {
	my $this=shift;

	$this->backup('');

	my $httpheader="HTTP/1.0 200 Ok\nContent-type: text/html\n\n";
	my $form='';
	my $id=0;
	my %idtoelt;
	foreach my $elt (@{$this->elements}) {
		# Each element has a unique id that it'll use on the form.
		$idtoelt{$id}=$elt;
		$elt->id($id++);
		my $html=$elt->show;
		if ($html ne '') {
			$form.=$html."<hr>\n";
		}
	}
	# If the elements generated no html, return now so we
	# don't display empty pages.
	return 1 if $form eq '';

	# Each form sent out has a unique id.
	my $formid=$this->formid(1 + $this->formid);

	# Add the standard header to the html we already have.
	$form="<html>\n<title>".$this->title."</title>\n<body>\n".
	       "<form><input type=hidden name=formid value=$formid>\n".
	       $form."<p>\n";

	# Should the back button be displayed?
	if ($this->capb_backup) {
		$form.="<input type=submit value=".gettext("Back")." name=back>\n";
	}
	$form.="<input type=submit value=".gettext("Next").">\n";
	$form.="</form>\n</body>\n</html>\n";

	my $query;
	# We'll loop here until we get a valid response from a client.
	do {
		$this->showclient($httpheader . $form);
	
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
	} until (defined $query->param('formid') &&
		 $query->param('formid') eq $formid);

	# Did they hit the back button? If so, ignore their input and inform
	# the ConfModule of this.
	if ($this->capb_backup && defined $query->param('back')  &&
	    $query->param('back') ne '') {
		return '';
	}

	# Now it's just a matter of matching up the element id's with values
	# from the form, and passing the values from the form into the
	# elements.
	foreach my $id ($query->param) {
		next unless $idtoelt{$id};
		
		$idtoelt{$id}->value($query->param($id));
		delete $idtoelt{$id};
	}
	# If there are any elements that did not get a result back, that in
	# itself is significant. For example, an unchecked checkbox will not
	# get anything back.
	foreach my $elt (values %idtoelt) {
		$elt->value('');
	}
	
	return 1;
}

=back

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
