#!/bin/env perl
use strict;
use warnings;

use CGI::Router;
use Data::Dumper;

my $r = CGI::Router->new();

my $something = 0;

my $callbacks = {
    '/' => sub { print "Matched /\n" },
    'foo' => sub { print "Matched foo\n" },
    'with-tokens' => sub {
        my ($tokens) = @_;
        print "Matched with-tokens\n";
        print Dumper $tokens;
    },
    'with-optional' => sub {
        my ($tokens) = @_;

        print "Matched with-optional\n";
        print Dumper $tokens;
    },
};

$r->add_route('GET', '/opt/:foo', sub { print Dumper \@_ })
    ->add_route('GET', '/',    $callbacks->{'/'}   )
    ->add_route('GET', '/foo', $callbacks->{'foo'} )
    ->add_route(
        'GET',
        '/with-tokens/:foo/:bar',
        $callbacks->{'with-tokens'},
        {
            foo => '[a-z]+',
            bar => '[a-z]+',
        },
    )
    ->add_route(
        'GET',
        '/with-optional/:foo(/:bar)?',
        $callbacks->{'with-optional'},
        {
            foo => '[a-z]+',
            bar => '[a-z]+',
        }
    );

$ENV{'REQUEST_METHOD'} = 'GET';

$ENV{'REQUEST_URI'} = '/';
$r->run();

$ENV{'REQUEST_URI'} = '/foo';
$r->run();

$ENV{'REQUEST_URI'} = '/with-tokens/one/two';
$r->run();


# This one will fail to match
$ENV{'REQUEST_URI'} = '/with-tokens/three';
$r->run();

# This one will fail to match
$ENV{'REQUEST_URI'} = '/with-tokens/4';
$r->run();


$ENV{'REQUEST_URI'} = '/with-optional/five/six';
$r->run();

$ENV{'REQUEST_URI'} = '/with-optional/seven';
$r->run();

# This one will fail to match
$ENV{'REQUEST_URI'} = '/with-optional/8';
$r->run();
