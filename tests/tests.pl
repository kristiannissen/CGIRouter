#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

# Adjust bin
use FindBin;
use lib "$FindBin::Bin/../CGI";

# Get the test framework
use Test::More;
use Test::Output;

use Data::Dumper; # We will be takin a dump

use CGI::Router qw/:standard/;

my $router = CGI::Router->new; # Create a router instance

# Lets get some tests rolling
isa_ok( $router, 'CGI::Router' );

# Test we have an add_route method
can_ok( $router, 'add_route' );

# The following shows how you index.pl file would look in a real web app
#
# router->add_route( 'GET', '/', sub {
#   print "This is the frontpage";
# });
#
# Lets add an /about-us page
#
# router->add_route( 'GET', '/about-us', sub {
#   print "Something about us";
# });

# Test that a GET request responds with the expected response
# Because we are on a command line we need to tamper with the ENV
# to make it look like a HTTP request has been fired. This could be run using
# LWP testing against localhost instead
$ENV{'REQUEST_URI'} = '/hello';
$ENV{'REQUEST_METHOD'} = 'GET';

sub get_response {
  $router->add_route( 'GET', '/hello', sub {

    print "Hello Kitty";
  });
  $router->run;
}
# diag( "Request is $ENV{'REQUEST_URI'}" );
stdout_like( \&get_response, qr/Hello Kitty/ );

# Lets test if CGI standard methods are available
# p() is one of the methods you can use in CGI
like( p( "Hello Pussy" ), qr/[hello pussy]/ );

# Lets test if this router is RESTful
# Fire a PUT request
$ENV{'REQUEST_URI'} = '/nestpas';
$ENV{'REQUEST_METHOD'} = 'PUT';

sub put_response {
  $router->add_route( 'PUT', '/nestpas', sub {

    print "n'est pas";
  });
  $router->run;
}
# diag( "Request is $ENV{'REQUEST_URI'}" );
stdout_like( \&put_response, qr/n'est pas/ );

# Let us test some tokens
$ENV{'REQUEST_URI'} = '/hello/kitty';
$ENV{'REQUEST_METHOD'} = 'GET';

sub token_response {
  $router->add_route( 'GET', '/hello/:what', sub {
    my $params = shift;
    my $what = $params->{'what'};

    print "Hello $what";
  });
  $router->run;
}
# diag( "Request is $ENV{'REQUEST_URI'}" );
stdout_like( \&token_response, qr/Hello kitty/ );

# Let us test some tokens
$ENV{'REQUEST_URI'} = '/die/kitty';
$ENV{'REQUEST_METHOD'} = 'DELETE';

sub delete_response {
  $router->add_route( 'DELETE', '/die/:what', sub {
    my $params = shift;
    my $what = $params->{'what'};;

    print "Die $what, die";
  });
  $router->run;
}
# diag( "Request is $ENV{'REQUEST_URI'}" );
stdout_like( \&delete_response, qr/Die kitty, die/ );

# Let us test some optional tokens
my @urls = qw(
  /run
  /run/forest
);
$ENV{'REQUEST_URI'} = $urls[rand @urls];
$ENV{'REQUEST_METHOD'} = 'POST';

sub optional_tokens_response {
  $router->add_route( 'POST', '/run(/:who)?', sub {

    print "Actor running";
  });
  $router->run;
}
# diag( "Request is $ENV{'REQUEST_URI'}" );
stdout_like( \&optional_tokens_response, qr/Actor Running/mi );

# Lets agree we are done testing
done_testing();
