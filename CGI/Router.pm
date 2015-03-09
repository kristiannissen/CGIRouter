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

        my ($pattern, $num_tokens) = $self->build_pattern( $route );

        if ($validations && scalar @$validations != $num_tokens) {
            croak sprintf(
                "Expected %d token validations, got %d",
                scalar @$validations,
                $num_tokens,
            );
        }

        $self->{routes}->{$method}->{$route} = {
            handler     => $handler,
            pattern     => $pattern,
            method      => $method,
            validations => $validations || [],
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

sub validate_params {
    my ($self, $route, $params) = @_;

    my $validations = $route->{'validations'};
    my $valid = 1;

    return $valid if (scalar @$validations == 0);

    for my $i (0..$#$params) {
        my $param   = $params->[$i];
        my $pattern = $validations->[$i];

        if ($param !~ /$pattern/) {
            carp sprintf("%s does not match pattern: %s", $param, $pattern);
            $valid = 0;
        }
    }

    return $valid;
}

sub mapper {
    my ($self) = @_;

    my $router;
    my @params;

    my $method = $ENV{'REQUEST_METHOD'};
    my $uri    = $ENV{'REQUEST_URI'};

    foreach my $key ( keys %{ $self->{routes}->{$method} } ) {
        my $route = $self->{routes}->{$method}->{$key};

        if ($uri =~ $route->{pattern}) {
            # Found the matching route
            @params = $uri =~ $route->{pattern};

            if (!$self->validate_params($route, \@params)) {
                return undef;
            }

            $router = $route;

            # Stop looking for more routes
            last;
        }
    }

    # Run hooks
    $self->run_hooks();

    # Handle the route
    return $router->{handler}->( @params );
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
    my ( $self, $pattern ) = @_;

    # Replace something like /word/:token with /word/(^:([a-z]+))
    # and count the replacements
    my $num_tokens = $pattern =~ s{
        (\:([a-z]+))
    }{
        if ($2) {
            "([^/]+)"
        }
    }gex;

    # Hint to Perl that this is a regular expression pattern
    # Also makes it more obvious what this is for
    return (qr/^$pattern$/, $num_tokens);
}

sub run {
    my ($self) = @_;

    return $self->mapper();
}

1;
