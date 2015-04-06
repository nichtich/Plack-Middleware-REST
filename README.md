# NAME

Plack::Middleware::REST - Route PSGI requests for RESTful web applications

# STATUS

[![Build Status](https://travis-ci.org/nichtich/Plack-Middleware-REST.png)](https://travis-ci.org/nichtich/Plack-Middleware-REST)
[![Coverage Status](https://coveralls.io/repos/nichtich/Plack-Middleware-REST/badge.png)](https://coveralls.io/r/nichtich/Plack-Middleware-REST)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Plack-Middleware-REST.png)](http://cpants.cpanauthors.org/dist/Plack-Middleware-REST)

# SYNOPSIS

    # $get, $update, $delete, $create, $list, $patch, $app must be PSGI applications
    builder {
        enable 'REST',
            get          => $get,           # GET /{id}
            upsert       => $update,        # PUT /{id}
            delete       => $delete,        # DELETE /{id}
            create       => $create,        # POST /
            list         => $list,          # GET /
            patch        => $patch,         # PATCH /{id}
            head         => 1,              # HEAD /{$id} => $get, HEAD / => $list
            options      => 1,              # support OPTIONS requests
            pass_through => 1,              # pass everything else to $app
            patch_types  => ['text/plain']; # optional accepted patch types
        $app;
    };

# DESCRIPTION

Plack::Middleware::REST routes HTTP requests (given in [PSGI](https://metacpan.org/pod/PSGI) request format)
on the principles of Representational State Transfer (REST). In short, the
application manages a set of resources with common base URL, each identified by
its URL. One can retrieve, create, update, delete, list, and patch resources
based on HTTP request methods.

Let's say an instance of Plack::Middleware::REST is mounted at the base URL
`http://example.org/item/`. The following HTTP request types can be
recognized, once they [have been assigned](#configuration):

- `POST http://example.org/item/`

    Calls the PSGI application `create` to create a new resource with URL assigned
    by the application.

- `GET http://example.org/item/123`

    Calls the application `get` to retrieve an existing resource identified by
    `http://example.org/item/123`.

- `PUT http://example.org/item/123`

    Calls the PSGI application `upsert` to either update an existing resource
    identified by `http://example.org/item/123` or to create a new resource with
    this URL. The application may reject updates and/or creation of new resources,
    acting like an update or insert method.

- `DELETE http://example.org/item/123`

    Calls the PSGI application `delete` to delete an existing resource identified
    by `http://example.org/item/123`.

- `GET http://example.org/item/`

    Calls the PSGI application `list` to get a list of existing resources.

- `PATCH http://example.org/item/123`

    Calls the PSGI application `patch` to update an existing resource
    identified by `http://example.org/item/123`. The application may
    reject updates of resources.

- `OPTIONS http://example.org/item/`

    Calls the PSGI application to return the allowed methods for the resource.

Other requests result either result in a PSGI response with error code 405 and
a list of possible request types in the `Accept` header, or the request is
passed to the underlying application in the middleware stack, if option
`pass_through` is set.

# CONFIGURATION

## get

## create

## upsert

## delete

## list

## patch

The options `get`, `create`, `upsert`, `delete`, `list`, `patch` can be set
to PSGI applications to enable the corresponding REST request type. One can also
use string aliases, including `app` to pass the request in the middleware stack:

    builder {
        enable 'REST',
            get          => 'app',   # pass GET requests on resource to $wrapped
            create       => $create, # pass POST to base URL to $create
            upsert       => $update; # pass PUT requests on resources to $update
            pass_through => 0;       # respond other requests with 405
        $wrapped;
    };

## head

By default (`head => 1`) the app configured to `get` and/or `list` resources
are also assumed to handle HEAD requests. Setting this configuration to `0` will
disallow HEAD requests. The special value `auto` will rewrite HEAD requests with
[Plack::Middleware::Head](https://metacpan.org/pod/Plack::Middleware::Head).

## options

By default (`options => 1`) the app is configured to handle OPTIONS requests
for a resource. Setting this configuration to `0` will dissallow OPTIONS requests.

## pass\_through

Respond to not allowed requests with HTTP 405. Enabled by default, but this may
change in a future version of this module!

## patch\_types

Optional array of acceptable patch document types for PATCH requests.
Respond to unacceptable patch document types with HTTP 415.

# COPYRIGHT AND LICENSE

Copyright 2014- Jakob Voß

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

# CONTRIBUTORS

Jakob Voß and Chris Kirke

# SEE ALSO

- [Plack::Middleware::REST::Util](https://metacpan.org/pod/Plack::Middleware::REST::Util), included with Plack::Middleware::REST
provides some utility methods to implement RESTful PSGI applications.  The
module may be removed in a future release.
- See [Plack::Middleware::Negotiate](https://metacpan.org/pod/Plack::Middleware::Negotiate) for content negotiation.
- See [Plack::Middleware::ETag](https://metacpan.org/pod/Plack::Middleware::ETag) for ETag generation.
- Alternative CPAN modules with similar scope include [Apache2::REST](https://metacpan.org/pod/Apache2::REST),
[REST::Utils](https://metacpan.org/pod/REST::Utils), [REST::Application](https://metacpan.org/pod/REST::Application), [WWW::REST::Apid](https://metacpan.org/pod/WWW::REST::Apid), [WWW::REST::Simple](https://metacpan.org/pod/WWW::REST::Simple),
[CGI::Application::Plugin::REST](https://metacpan.org/pod/CGI::Application::Plugin::REST), and [Plack::App::REST](https://metacpan.org/pod/Plack::App::REST).  Moreover
there are general web application frameworks like [Dancer](https://metacpan.org/pod/Dancer)/[Dancer2](https://metacpan.org/pod/Dancer2),
[Mojolicious](https://metacpan.org/pod/Mojolicious), and [Catalyst](https://metacpan.org/pod/Catalyst). Maybe the number of such modules and
frameworks is higher than the number of actual web APIs written in Perl. Who
knows?
- REST client modules at CPAN include [REST::Client](https://metacpan.org/pod/REST::Client), [Eixo::Rest](https://metacpan.org/pod/Eixo::Rest),
[REST::Consumer](https://metacpan.org/pod/REST::Consumer), [Net::Rest::Generic](https://metacpan.org/pod/Net::Rest::Generic), [LWP::Simple::REST](https://metacpan.org/pod/LWP::Simple::REST), and
[WWW:.REST](WWW:.REST), [Role::REST::Client](https://metacpan.org/pod/Role::REST::Client), [Rest::Client::Builder](https://metacpan.org/pod/Rest::Client::Builder),
[MooseX::Role::REST::Consumer](https://metacpan.org/pod/MooseX::Role::REST::Consumer). Don't ask why.
