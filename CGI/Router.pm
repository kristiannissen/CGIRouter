package CGI::Router;

use strict;
use warnings;

use parent 'CGI';

use Cwd  qw(abs_path);
use Carp qw(carp croak);

use Data::Dumper;

sub setup {
    my ( $self, $config ) = @_;

    $config->{layout} //= {};
    $config->{hooks}  //= {};

    $self->{config} = {
        layout => $config->{layout},
        hooks  => $config->{hooks},
    };

    return $self;
}

sub add_route {
    my ($self, $method, $route, $handler, $validations) = @_;

    $self->{routes} //= {};

    if ( ! exists $self->{routes}->{$method}->{$route} ) {

        my $pattern = $self->build_pattern( $route, $validations );

        $self->{routes}->{$method}->{$route} = {
            handler     => $handler,
            pattern     => $pattern,
            method      => $method,
            validations => $validations || {},
        };
    } else {
        croak( "Similar request already exists $method $route!" );
    }

    return $self;
}

sub render_markup {
    my ( $self, $template_file, $template_vars, $template_master ) = @_;
    my $output = '';

    my $conf = $self->{config}->{layout};

    $self->set_header( $template_file =~ /\.([a-z]{1,})/ );
    print $output;

    return $self;
}

sub render_txt {
    my ( $self, $txt ) = @_;

    $self->set_header( 'text' );
    print $txt;

    return $self;
}

sub set_header {
    my ( $self, $content_type ) = @_;

    if ( lc $content_type eq 'html' ) {
        print $self->header( -type => 'text/html', -charset => 'utf-8' );
    }
    if ( lc $content_type eq 'text' ) {
      print $self->header( -type => 'text/plain', -charset => 'utf-8' );
    }

    return $self;
}

sub mapper {
    my ($self) = @_;

    my $router;
    my $params = {};

    my $method = $ENV{'REQUEST_METHOD'};
    my $uri    = $ENV{'REQUEST_URI'};

    foreach my $key ( keys %{ $self->{routes}->{$method} } ) {
        my $route = $self->{routes}->{$method}->{$key};

        if (my @matches = $uri =~ $route->{pattern}) {
            %{$params} = %+; # %LAST_PAREN_MATCH;
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

    if ($num_tokens != scalar keys %$token_regexes) {
        croak sprintf(
            "Expected %d token regexes, got %d",
            scalar keys %$token_regexes,
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
