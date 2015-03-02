#!/usr/bin/perl

use strict;
use warnings;

# Adjust bin
use FindBin;
use lib "$FindBin::Bin/../CGI";

# Get the test framework
use Test::More;

use CGI::Router qw/:standard/;

my $router = CGI::Router->new;

# Lets get some tests rolling
isa_ok( $router, 'CGI::Router' );

# Test we have a connect method
can_ok( $router, 'connect' );

# Lets agree we are done testing
done_testing();