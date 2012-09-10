package RESTApp;
use strict;
use warnings;

use Plack::Request;
use HTTP::Status qw(status_message);

sub new { 
	bless { hash => {}, count => 0 }, shift; 
}

## helper methods

sub id {
    substr($_[0]->{PATH_INFO} || '/',1);
}

sub response {
	my $code = shift;
	my $body = @_ ? shift : status_message($code); 
	[ $code, [ 'Content-Type' => 'text/plain', @_ ], [ $body ] ];
}

sub uri {
    my $env = shift;
    my $id  = @_ ? shift : id($env);
	my $uri = Plack::Request->new($env)->base;
	$uri .= '/' unless $uri =~ qr{/$}; # needed if mounted (?)
	return $uri . $id;
}

sub content {
	defined $_[0]->{CONTENT_LENGTH}
		? Plack::Request->new($_[0])->content
		: undef;
}

## methods

sub resource {
	my ($self,$env) = @_;
	$self->{hash}->{ id($env) };
}

sub get {
	my ($self,$env) = @_;
	my $resource = $self->resource($env);
	return defined $resource ? response( 200 => $resource ) : response(404);
}

sub create {
	my ($self,$env) = @_;
	my $resource = content($env);
	return response(400) unless defined $resource;

	my $id = ++$self->{count};
	$self->{hash}->{ $id } = $resource;

    my $uri = uri($env,$id);
	return response(201, $resource, Location => $uri); # or 204
}

sub update {
	my ($self,$env) = @_;
	
	return response(404) unless defined $self->resource($env);

	my $resource = content($env);
	return response(400) unless defined $resource;

	$self->{hash}->{ id($env) } = $resource;
	return response(200,$resource); # or 204
}

sub delete {
	my ($self,$env) = @_;
	return (defined (delete $self->{hash}->{ id($env) })) 
		? response(204,'') : response(404);
}

sub list {
	my ($self,$env) = @_;
    my @uris = map { uri($env,$_) } keys %{$self->{hash}}; 
    response(200, join "\n", @uris);
}

1;
