# NAME

Plack::Middleware::REST - Route PSGI requests for RESTful web applications

# STATUS

[![Build Status](https://travis-ci.org/nichtich/Plack-Middleware-REST.png)](https://travis-ci.org/nichtich/Plack-Middleware-REST)
[![Coverage Status](https://coveralls.io/repos/nichtich/Plack-Middleware-REST/badge.png)](https://coveralls.io/r/nichtich/Plack-Middleware-REST)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Plack-Middleware-REST.png)](http://cpants.cpanauthors.org/dist/Plack-Middleware-REST)

# SYNOPSIS

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

# DESCRIPTION

Plack::Middleware::REST routes HTTP requests (given in [PSGI](https://metacpan.org/pod/PSGI) request format)
on the principles of Representational State Transfer (REST). In short, the
application manages a set of resources with common base URL, each identified by
its URL. One can retrieve, create, update, delete, and list resources based on
HTTP request methods.

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

Additional HTTP request types `HEAD`, `OPTIONS`, and `PATCH` may be added in
a later version of this module.

Other requests result either result in a PSGI response with error code 405 and
a list of possible request types in the `Accept` header, or the request is
passed to the underlying application in the middleware stack, if option
`pass_through` is set.

# CONFIGURATION

The options `get`, `create`, `upsert`, `delete`, `list` can be set to PSGI
applications to enable the corresponding REST request type. One can also use
string aliases, including `app` to pass the request in the middleware stack:

    builder {
        enable 'REST',
            get          => 'app',   # pass GET requests on resource to $wrapped
            create       => $create, # pass POST to base URL to $create
            upsert       => $update; # pass PUT requests on resources to $update
            pass_through => 0;       # respond other requests with 405
        $wrapped;
    };

# COPYRIGHT AND LICENSE

Copyright 2014- Jakob Voß

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

# CONTRIBUTORS

Jakob Voß and Chris Kirke

# SEE ALSO

[Plack::Middleware::REST::Util](https://metacpan.org/pod/Plack::Middleware::REST::Util) provides some utility methods to implement
RESTful PSGI applications with Plack::Middleware::REST.  See
[Plack::Middleware::Negotiate](https://metacpan.org/pod/Plack::Middleware::Negotiate) for content negotiation.
