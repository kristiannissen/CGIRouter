package CGI::Router;

use strict;
use warnings;

use parent 'CGI';

use Cwd  qw(abs_path);
use Carp qw(croak);

use Data::Dumper;

sub setup {
    my ( $self, $config ) = @_;

    $config->{db}     //= {};
    $config->{log}    //= {};
    $config->{layout} //= {};
    $config->{hooks}  //= {};

    $self->{config} = {
        db     => $config->{db},
        log    => $config->{log},
        layout => $config->{layout},
        hooks  => $config->{hooks},
    };

    return $self;
}

sub add_route {
    my ($self, $method, $route, $handler) = @_;

    $self->{routes} //= {};

    if ( ! exists $self->{routes}->{$method}->{$route} ) {
        $self->{routes}->{$method}->{$route} = {
            handler => $handler,
            pattern => $self->build_pattern( $route ),
            method  => $method,
        };
    } else {
        croak( "Similar request already exists $method $route!" );
    }

    return $self;
}

sub render_markup {
    my ( $self, $template_file, $template_vars ) = @_;
    my $conf = $self->{config}->{layout};

    my $template      = "$conf->{templatepath}/$template_file";
    my %template_vars = %{$template_vars};

    my $output;

    if ( open( my $fh, "<:encoding(UTF-8)", $template ) ) {
        while ( my $row = <$fh> ) {
            $row =~ s{[\f\n\r]*$}{};
            $output .= $row;
        }
        close($fh);
    }
    else {
        croak("Could not open $template");
    }

    foreach my $key ( keys \%template_vars ) {
        my $val     = $template_vars{$key};
        my $pattern = $key;

        $output =~ s/{$key}/$val/g;
    }

    if ( exists $conf->{master} ) {
        my $master = "$conf->{templatepath}/$conf->{master}";
        my $master_output;
        if ( open( my $fh, "<:encoding(UTF-8)", $master ) ) {
            while ( my $row = <$fh> ) {
                chomp $row;
                $master_output .= $row;
            }
        }
        else {
            croak("Could not open $master");
        }

        $master_output =~ s/{yield}/$output/g;
        $output = $master_output;
    }

    $self->logger('Rendering output');

    $self->set_header( $template_file =~ /\.([a-z]{1,})/ );
    print $output;

    return $self;
}

sub render_txt {
    my ( $self, $txt ) = @_;

    print $txt;

    return $self;
}

sub set_header {
    my ( $self, $content_type ) = @_;

    if ( lc $content_type eq 'html' ) {
        print $self->header( -type => 'text/html', -charset => 'utf-8' );
    }

    return $self;
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

sub logger {
    my ( $self, $msg ) = @_;

    if ( exists $self->{log} ) {
        my $file_path = $self->{config}->{log}->{path};
        my $level = $self->{config}->{log}->{level};

        open my $fh, ">>", "$file_path/$level.log";
        print $fh sprintf("[T:%s] [%s] - %s \n", time, $level, $msg);
        close $fh;
    }

    return $self;
}

sub run_hooks {
    my ($self) = @_;
    my $hooks = $self->{config}->{hooks};

    $self->logger( 'Running hooks before_each' );
    # Run each subroutine
    if (ref $hooks->{before_each} eq 'CODE') {
        $hooks->{before_each}->( $self );
    }

    return $self;
}

sub build_pattern {
    my ( $self, $pattern ) = @_;

    # do block returns complex regex
    $pattern = do {
        # Replace something like /word/:token with /word/(^:([a-z]+))
        $pattern =~ s!
            (\:([a-z]+))
        !
            if ( $2 ) {
                "([^/]+)"
            }
        !gex;

        "^$pattern\$";
    };

    # Hint to Perl that this is a regular expression pattern
    # Also makes it more obvious what this is for
    return qr/$pattern/;
}

sub run {
    my ($self) = @_;

    return $self->mapper();
}

1;
