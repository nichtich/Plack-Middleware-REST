package Plack::Middleware::REST;
#ABSTRACT: Route PSGI requests for RESTful web applications
use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(reftype);

use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(get head create upsert delete list pass_through);

our %METHOD = (
	resource   => {
	    GET    => 'get',
    	PUT    => 'upsert', 
	    DELETE => 'delete',
	},
	collection => {
		GET	   => 'list',
		POST   => 'create',
	},
);

sub prepare_app {
	my ($self) = @_;

	$self->pass_through(0)
		unless defined $self->pass_through;

	my @actions = qw(get head create upsert delete list);
	foreach my $action (@actions)  {
		my $app = $self->{$action};

		# alias
		$self->{$action} = $self->{$app} if $app and !ref $app;

		croak "PSGI application '$action' must be code reference"
			if $self->{action} and (reftype($self->{$action}) || '') ne 'CODE';
	}

	while (my ($type,$method) = each %METHOD) {
		my @allow = sort grep { $self->{ $method->{$_} } } keys %$method;
		$self->{allow}->{$type} = \@allow;
	}
}

sub call {
	my ($self, $env) = @_;

	my $type   = ($env->{PATH_INFO} || '/') eq '/' 
		? 'collection' : 'resource';

	my $method = $METHOD{ $type }->{ $env->{REQUEST_METHOD} };

	my $app = $method ? $self->{ $method } : undef;

	$app ||= $self->{app} if $self->pass_through; 

	if ( $app ) {
		$app->($env);
	} else {
		my $allow = join ', ', @{ $self->{allow}->{$type} };
	    [ 405, [ Allow => $allow ], ['Method Not Allowed'] ];
	}
}

1;

=head1 SYNOPSIS

	builder {
		enable 'REST',
			get    => $get,       # HTTP GET on a resource
			create => $create,    # HTTP POST in '/'
			upsert => $update,    # HTTP PUT on a resource
			head   => 'get'       # alias (use same app $get)
			list   => $list,      # HTTP GET on '/'
			pass_through => 1;    # pass if no defined REST request
		$app; 
	};

=cut
