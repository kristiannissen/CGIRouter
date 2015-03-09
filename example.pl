#!/bin/env perl
use strict;
use warnings;

use CGI::Router;

my $r = CGI::Router->new();

$r->add_route('GET', '/',    sub { print "index.html\n" });
$r->add_route('GET', '/foo', sub { print "foo.html\n"}   );
$r->add_route('GET', '/:foo/:bar', sub { my ($foo, $bar) = @_; print "I $foo\'d a $bar\n" }, ['[a-z]+', '[a-z]+']);

$ENV{'REQUEST_METHOD'} = 'GET';

$ENV{'REQUEST_URI'} = '/';
$r->run();

$ENV{'REQUEST_URI'} = '/foo';
$r->run();

$ENV{'REQUEST_URI'} = '/splarg/wibble';
$r->run();

# This one will fail to run
$ENV{'REQUEST_URI'} = '/splarg/42';
$r->run();
