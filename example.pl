#!/bin/env perl
use strict;
use warnings;

use CGI::Router;

my $r = CGI::Router->new();

$r->add_route('GET', '/',    sub { print "index.html\n" });
$r->add_route('GET', '/foo', sub { print "foo.html\n"}   );
$r->add_route(
    'GET',
    '/:foo/:bar',
    sub {
        my ($tokens) = @_;
        print sprintf(
            "I %s\'d a %s\n",
            $tokens->{'foo'},
            $tokens->{'bar'},
        );
    },
    {
        foo => '[a-z]+',
        bar => '[a-z]+',
    },
);

$ENV{'REQUEST_METHOD'} = 'GET';

$ENV{'REQUEST_URI'} = '/';
$r->run();

$ENV{'REQUEST_URI'} = '/foo';
$r->run();

$ENV{'REQUEST_URI'} = '/splarg/wibble';
$r->run();

# This one will fail to match
$ENV{'REQUEST_URI'} = '/splarg/42';
$r->run();
