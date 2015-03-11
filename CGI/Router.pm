package CGI::Router;

use strict;
use warnings;

use parent 'CGI';

use Carp qw(carp croak);

sub setup {
    my ( $self, $config ) = @_;

    $config->{hooks}  //= {};

    $self->{config} = {
        hooks  => $config->{hooks},
    };

    return $self;
}

sub add_route {
    my ($self, $method, $route, $handler, $token_regexes) = @_;

    $token_regexes  //= {};
    $self->{routes} //= {};

    if ( ! exists $self->{routes}->{$method}->{$route} ) {

        my $pattern = $self->build_pattern( $route, $token_regexes );

        $self->{routes}->{$method}->{$route} = {
            handler     => $handler,
            pattern     => $pattern,
            method      => $method,
        };
    } else {
        croak( "Similar request already exists $method $route!" );
    }

    return $self;
}

sub mapper {
    my ($self) = @_;

    my ($router, $params);

    my $method = $ENV{'REQUEST_METHOD'};
    my $uri    = $ENV{'REQUEST_URI'};

    foreach my $key ( keys %{ $self->{routes}->{$method} } ) {
        my $route = $self->{routes}->{$method}->{$key};

        if ($uri =~ $route->{pattern}) {
            %{$params} = %+; # %LAST_PAREN_MATCH;
            if (scalar keys %$params == 0) {
                undef($params);
            }
            $router = $route;

            # Stop looking for more routes
            last;
        }
    }

    if (!$router) {
        carp "No matching route for $uri";
        return undef;
    }

    # Run hooks
    $self->run_hooks();

    # Handle the route
    return $router->{handler}->( $params );
}

sub run_hooks {
    my ($self) = @_;
    my $hooks = $self->{config}->{hooks};

    # Run each subroutine
    if (ref $hooks->{before_each} eq 'CODE') {
        $hooks->{before_each}->( $self );
    }

    return $self;
}

sub build_pattern {
    my ( $self, $pattern, $token_regexes ) = @_;

    my $num_regexes = scalar keys $token_regexes;
    my $token_regex = '[^/]+';

    # Replace something like /word/:token with /word/(^:([a-z]+))
    # and count the replacements
    my $num_tokens = $pattern =~ s{
        (\:([a-z0-9]+))
    }{
        if ($2) {
            my $expr = $token_regex;
            if (exists $token_regexes->{$2}) {
                $expr = $token_regexes->{$2};
            }
            "(?<$2>$expr)";
        }
    }gex;

    if ($num_regexes and $num_tokens != $num_regexes) {
        croak sprintf(
            "Expected %d token regexes, got %d",
            $num_regexes,
            $num_tokens,
        );
    }

    # Hint to Perl that this is a regular expression pattern
    # Also makes it more obvious what this is for
    return qr/^$pattern$/; #, $num_tokens);
}

sub run {
    my ($self) = @_;

    return $self->mapper();
}

1;
