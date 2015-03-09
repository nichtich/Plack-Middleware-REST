package Plack::Middleware::REST;
#ABSTRACT: Route PSGI requests for RESTful web applications
use strict;
use warnings;

our $VERSION = '0.03';

use Carp qw(croak);
use Scalar::Util qw(reftype);

use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(get create upsert delete list pass_through);

our %METHOD = (
    resource   => {
        GET    => 'get',
        PUT    => 'upsert',
        DELETE => 'delete',
    },
    collection => {
        GET       => 'list',
        POST   => 'create',
    },
);

sub prepare_app {
    my ($self) = @_;

    $self->pass_through(0)
        unless defined $self->pass_through;

    my @actions = qw(get create upsert delete list);
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

=encoding utf8

=head1 SYNOPSIS

    # $get, $create, $update, $list, $app must be PSGI applications
    builder {
        enable 'REST',
            get          => $get,      # HTTP GET on a resource
            create       => $create,   # HTTP POST in '/'
            upsert       => $update,   # HTTP PUT on a resource
            list         => $list,     # HTTP GET on '/'
            pass_through => 1;         # pass if no defined REST request
        $app;
    };

=head1 DESCRIPTION

Plack::Middleware::REST routes HTTP requests (given in L<PSGI> request format)
on the principles of Representational State Transfer (REST). In short, the
application manages a set of resources with common base URL, each identified by
its URL. One can retrieve, create, update, delete, and list resources based on
HTTP request methods.

Let's say an instance of Plack::Middleware::REST is mounted at the base URL
C<http://example.org/item/>. The following HTTP request types can be
recognized, once they L<have been assigned|/CONFIGURATION>:

=over 4

=item C<POST http://example.org/item/>

Calls the PSGI application C<create> to create a new resource with URL assigned
by the application.

=item C<GET http://example.org/item/123>

Calls the application C<get> to retrieve an existing resource identified by
C<http://example.org/item/123>.

=item C<PUT http://example.org/item/123>

Calls the PSGI application C<upsert> to either update an existing resource
identified by C<http://example.org/item/123> or to create a new resource with
this URL. The application may reject updates and/or creation of new resources,
acting like an update or insert method.

=item C<DELETE http://example.org/item/123>

Calls the PSGI application C<delete> to delete an existing resource identified
by C<http://example.org/item/123>.

=item C<GET http://example.org/item/>

Calls the PSGI application C<list> to get a list of existing resources.

=back

Additional HTTP request types C<HEAD>, C<OPTIONS>, and C<PATCH> may be added in
a later version of this module.

Other requests result either result in a PSGI response with error code 405 and
a list of possible request types in the C<Accept> header, or the request is
passed to the underlying application in the middleware stack, if option
C<pass_through> is set.

=head1 CONFIGURATION

The options C<get>, C<create>, C<upsert>, C<delete>, C<list> can be set to PSGI
applications to enable the corresponding REST request type. One can also use
string aliases, including C<app> to pass the request in the middleware stack:

    builder {
        enable 'REST',
            get          => 'app',   # pass GET requests on resource to $wrapped
            create       => $create, # pass POST to base URL to $create
            upsert       => $update; # pass PUT requests on resources to $update
            pass_through => 0;       # respond other requests with 405
        $wrapped;
    };

=head1 COPYRIGHT AND LICENSE

Copyright 2014- Jakob Voß

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Plack::Middleware::REST::Util> provides some utility methods to implement
RESTful PSGI applications with Plack::Middleware::REST.  See
L<Plack::Middleware::Negotiate> for content negotiation.

=cut
