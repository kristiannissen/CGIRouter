# CGIRouter

Out of the box CGI qw/:standard/ offers many of the features you would expect from a web framework,
it has methods for creating HTML markup like anchors, paragraphs and H tags. CGI may not be as sexy
as some of the modern frameworks.

I was recently facing the challenge of building a simple website based on Perl and adding a framework, any 
framework, would mean adding modules and dependencies which would then have to be kept  up to date, as well 
as spending time on understanding the framework in question, it's cons and pros in order to pick the best 
one suited for the task at hand.

I realised, the only thing I needed was a simple router to manage the different requests coming to the
website and show content!

And here you are! A module that extends CGI and offers simple RESTful routing.

## How to use
Since the CGIRouter extends CGI you can initialize the module like in the example below and pass your standard CGI parameters as you usually do
```Perl
use strict;
use warnings;

use CGI::Router qw/:standard/;

my $router = CGI::Router->new; # Now create your CGIRouter class

# Matches a HTTP GET /hello request
$router->add_route( 'GET', '/hello', sub {
  print "Hello Kitty";
});

$router->add_route( 'GET', '/kitty', sub {
  print p("Hello Kitty"); # Make use of CGI to print paragraph
});

$router->run(); # Executes your app so that what ever request is coming in gets handled
```
### Check the tests.pl file
If you want more examples I suggest you check the https://github.com/kristiannissen/CGIRouter/blob/master/tests/tests.pl file for now.
