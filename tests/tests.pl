#!/usr/bin/perl

use strict;
use warnings;

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
#   return router->render_html( 'homepage.html', {});
# });
#
# Lets add an /about-us page
#
# router->add_route( 'GET', '/about-us', sub {
#   return router->render_html( 'about-us.html', {});
# });

# Test that a GET request responds with the expected response
# Because we are on a command line we need to tamper with the ENV
# to make it look like a HTTP request has been fired. This could be run using
# LWP testing against localhost instead
$ENV{'REQUEST_URI'} = '/hello';
$ENV{'REQUEST_METHOD'} = 'GET';

sub get_response {
  $router->add_route( 'GET', '/hello', sub {
    return $router->render_txt( "Hello Kitty" );
  });
  $router->run;
}

# Lets capture some STDOUT put
stdout_is( \&get_response, "Hello Kitty", "The Hello Kitty test" );

# Lets test if CGI standard methods are available
# p() is one of the methods you can use in CGI
like( p( "Hello Pussy" ), qr/[hello pussy]/, "The Hello Pussy test" );

# Lets test if this router is RESTful
# Fire a PUT request
$ENV{'REQUEST_URI'} = '/nestpas';
$ENV{'REQUEST_METHOD'} = 'PUT';
sub put_response {
  $router->add_route( 'PUT', '/nestpas', sub {
    return $router->render_txt( "n'est pas" );
  });
  $router->run;
}
stdout_is( \&put_response, "n'est pas", "The je ne parle pas française test" );

# Let us test some tokens
$ENV{'REQUEST_URI'} = '/hello/kitty';
$ENV{'REQUEST_METHOD'} = 'GET';
sub token_response {
  $router->add_route( 'GET', '/hello/:what', sub {
    my $what = shift;

    return $router->render_txt( "Hello $what" );
  });
  $router->run;
}
stdout_is( \&token_response, "Hello kitty", "The token test" );

# Let us test some tokens
$ENV{'REQUEST_URI'} = '/die/kitty';
$ENV{'REQUEST_METHOD'} = 'DELETE';
sub delete_response {
  $router->add_route( 'DELETE', '/die/:what', sub {
    my $what = shift;

    return $router->render_txt( "Die $what, die" );
  });
  $router->run;
}
stdout_is( \&delete_response, "Die kitty, die", "The kill a kitten test" );

# Lets agree we are done testing
done_testing();
