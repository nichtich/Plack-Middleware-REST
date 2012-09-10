use strict;
use warnings;
use Test::More;

use Plack::Test;
use Plack::Builder;
use Plack::Middleware::REST;

use HTTP::Request::Common qw(GET PUT POST DELETE HEAD);
use HTTP::Status qw(status_message);

use lib 't/lib';
use RESTApp;

my $backend = RESTApp->new;

my $app = builder {
	enable 'REST',
		head   => 'get',
		get    => sub { $backend->get(@_) },
		create => sub { $backend->create(@_) },
		upsert => sub { $backend->update(@_) },
		delete => sub { $backend->delete(@_) };
	sub { [501,[],[status_message(501)]] };
};

test_psgi $app, sub {
	my $cb  = shift;

	my $res = $cb->(GET '/');
	is $res->code, '405', 'GET / not allowed';
	is $res->header('Allow'), 'POST', 'use POST to create';

	$res = $cb->(GET '/1');
	is $res->code, '404', 'empty collection';

	$res = $cb->(POST '/', Content => 'hello', 'Content-Type' => 'text/plain');
	is $res->code, 201, 'created';
	is $res->header('Location'), 'http://localhost/1', 'with new URI';

	$res = $cb->(GET '/1');
	is $res->code, '200', 'found';
	is $res->content, 'hello', 'got back';

	$res = $cb->(PUT '/1', Content => 'world', 'Content-Type' => 'text/plain');
	is $res->code, 200, 'updated';

	$res = $cb->(GET '/1');
	is $res->content, 'world', 'modified';

	$res = $cb->(POST '/1');
	is $res->code, '405', 'POST on resource not allowed';
	is $res->header('Allow'), 'DELETE, GET, PUT', 'use DELETE, GET, PUT';

	$res = $cb->(DELETE '/1');
	is $res->code, '204', 'deleted resource';

	$res = $cb->(GET '/1');
	is $res->code, '404', 'resource gone';

	use Data::Dumper;
	print Dumper($res);
};

done_testing;
