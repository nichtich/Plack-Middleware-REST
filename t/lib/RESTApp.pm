package RESTApp;
use strict;
use warnings;

use Plack::Request;
use HTTP::Status qw(status_message);

sub response {
	my $code = shift;
	my $body = @_ ? shift : status_message($code); 
	[ $code, [ 'Content-Type' => 'text/plain', @_ ], [ $body ] ];
}

sub new { 
	bless { hash => {}, count => 0 }, shift; 
}

sub id {
	my ($self,$env) = @_;
    substr($env->{PATH_INFO} || '/',1);
}

sub content {
	my ($self,$env) = @_;
	defined $env->{CONTENT_LENGTH}
		? Plack::Request->new($env)->content
		: undef;
}

sub resource {
	my ($self,$env) = @_;
	$self->{hash}->{ $self->id($env) };
}

sub get {
	my ($self,$env) = @_;
	my $resource = $self->resource($env);
	return defined $resource ? response( 200 => $resource ) : response(404);
}

sub create {
	my ($self,$env) = @_;
	my $resource = $self->content($env);
	return response(400) unless defined $resource;

	my $id = ++$self->{count};
	$self->{hash}->{ $id } = $resource;

	my $uri = Plack::Request->new($env)->base;
	$uri .= '/' unless $uri =~ qr{/$}; # needed if mounted (?)
	$uri .= $id;

	my $location = "..."; # TODO
	return response(201, $resource, Location => $uri); # or 204
}

sub update {
	my ($self,$env) = @_;
	
	return response(404) unless defined $self->resource($env);

	my $resource = $self->content($env);
	return response(400) unless defined $resource;

	$self->{hash}->{ $self->id($env) } = $resource;
	return response(200,$resource); # or 204
}

sub delete {
	my ($self,$env) = @_;
	return (defined (delete $self->{hash}->{ $self->id($env) })) 
		? response(204,'') : response(404);
}

1;
