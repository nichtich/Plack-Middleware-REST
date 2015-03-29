package Plack::Middleware::REST;
use strict;
use warnings;

our $VERSION = '0.03';

use Carp qw(croak);
use Scalar::Util qw(reftype);

use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(get create upsert delete list head pass_through routes options);

use Plack::Middleware::Head;

sub prepare_app {
    my ($self) = @_;

    $self->pass_through(0) unless defined $self->pass_through;
    $self->head(1) unless defined $self->head;
    $self->options(1) unless defined $self->options;

    $self->routes({
        resource   => {
            GET    => 'get',
            PUT    => 'upsert',
            DELETE => 'delete',
        },
        collection => {
            GET    => 'list',
            POST   => 'create',
        },
    });

    if ($self->head) {
        $self->routes->{resource}->{HEAD} = 'get';
        $self->routes->{collection}->{HEAD} = 'list';
    }

    foreach my $action (qw(get create upsert delete list))  {
        my $app = $self->{$action};

        # alias
        $self->{$action} = $self->{$app} if $app and !ref $app;

        croak "PSGI application '$action' must be code reference"
            if $self->{action} and (reftype($self->{$action}) || '') ne 'CODE';
    }

    while (my ($type, $route) = each %{$self->routes}) {
        $self->{allow}->{$type} = join ', ',
            sort grep { $self->{ $route->{$_} } } keys %$route;
        foreach my $method (keys %$route) {
            $route->{$method} = $self->{ $route->{$method} };
        }
        if ($self->head eq 'auto') {
            $route->{HEAD} = Plack::Middleware::Head->wrap($route->{HEAD});
        }
    }
}

sub call {
    my ($self, $env) = @_;

    my $type   = ($env->{PATH_INFO} || '/') eq '/' ? 'collection' : 'resource';
    my $method = $env->{REQUEST_METHOD};

    if ($method eq 'OPTIONS') {
        if ($self->options) {
            [ 200, [ Allow => $self->{allow}->{$type} ], [] ];
        } else {
            [ 405, [ Allow => $self->{allow}->{$type} ], ['Method Not Allowed'] ];
        }
    } else {
        my $app    = $self->routes->{$type}->{$method};
        $app ||= $self->{app} if $self->pass_through;
        if ( $app ) {
            $app->($env);
        } else {
            [ 405, [ Allow => $self->{allow}->{$type} ], ['Method Not Allowed'] ];
        }
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Plack::Middleware::REST - Route PSGI requests for RESTful web applications

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/nichtich/Plack-Middleware-REST.png)](https://travis-ci.org/nichtich/Plack-Middleware-REST)
[![Coverage Status](https://coveralls.io/repos/nichtich/Plack-Middleware-REST/badge.png)](https://coveralls.io/r/nichtich/Plack-Middleware-REST)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Plack-Middleware-REST.png)](http://cpants.cpanauthors.org/dist/Plack-Middleware-REST)

=end markdown

=head1 SYNOPSIS

    # $get, $update, $delete, $create, $list, $app must be PSGI applications
    builder {
        enable 'REST',
            get          => $get,      # GET /{id}
            upsert       => $update,   # PUT /{id}
            delete       => $delete,   # DELETE /{id}
            create       => $create,   # POST /
            list         => $list,     # GET /
            head         => 1,         # HEAD /{$id} => $get, HEAD / => $list
            options      => 1,         # support OPTIONS requests
            pass_through => 1;         # pass everything else to $app
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

=item C<OPTIONS http://example.org/item/>

Calls the PSGI application to return the allowed methods for the resource.

=back

Additional HTTP request type C<PATCH> may be added in a later version of this module.

Other requests result either result in a PSGI response with error code 405 and
a list of possible request types in the C<Accept> header, or the request is
passed to the underlying application in the middleware stack, if option
C<pass_through> is set.

=head1 CONFIGURATION

=head2 get

=head2 create

=head2 upsert

=head2 delete

=head2 list

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

=head2 head

By default (C<head =E<gt> 1>) the app configured to C<get> and/or C<list> resources
are also assumed to handle HEAD requests. Setting this configuration to C<0> will
disallow HEAD requests. The special value C<auto> will rewrite HEAD requests with
L<Plack::Middleware::Head>.

=head2 options

By default (C<options =E<gt> 1>) the app is configured to handle OPTIONS requests
for a resource. Setting this configuration to C<0> will dissallow OPTIONS requests.

=head2 pass_through

Respond to not allowed requests with HTTP 405. Enabled by default, but this may
change in a future version of this module!

=head1 COPYRIGHT AND LICENSE

Copyright 2014- Jakob Voß

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 CONTRIBUTORS

Jakob Voß and Chris Kirke

=head1 SEE ALSO

=over

=item

L<Plack::Middleware::REST::Util>, included with Plack::Middleware::REST
provides some utility methods to implement RESTful PSGI applications.

=item

See L<Plack::Middleware::Negotiate> for content negotiation.

=item

Alternative CPAN modules with similar scope include L<Apache2::REST>,
L<REST::Utils>, L<REST::Application>, L<WWW::REST::Apid>, L<WWW::REST::Simple>,
L<CGI::Application::Plugin::REST>, and L<Plack::Middleware::RestAPI>.  Moreover
there are general web application frameworks like L<Dancer>/L<Dancer2>,
L<Mojolicious>, and L<Catalyst>. Maybe the number of such modules and
frameworks is higher than the number of actual web APIs written in Perl. Who
knows?

=item

REST client modules at CPAN include L<REST::Client>, L<Eixo::Rest>,
L<REST::Consumer>, L<Net::Rest::Generic>, L<LWP::Simple::REST>, and
L<WWW:.REST>, L<Role::REST::Client>, L<Rest::Client::Builder>,
L<MooseX::Role::REST::Consumer>. Don't ask why.

=back

=cut
