package CGI::Router;

use strict;
use warnings;

use parent 'CGI';
use Cwd 'abs_path';
use Carp;

use Data::Dumper;

sub setup {
  my ( $self, $config ) = @_;

  $self->{config} = {
    db => $config->{db} //= {},
    log => $config->{log} //= {},
    layout => $config->{layout} //= {},
    hooks => $config->{hooks} //= {}
  };
}

sub connect {
  my ( $self, $req, $subr ) = @_;
  
  $self->{routes} //= {};
  $self->{env} //= \%ENV;

  if ( ! exists $self->{routes}->{$req} ) {
    $self->{routes}->{$req} = {
      handler => $subr,
      pattern => $self->build_pattern( $req ),
      method => $req =~ /^(GET|PUT|POST|DELETE)/
    };
  } else {
    Carp::croak( "Similar request already exists $req!" );
  }
  
  # Get current request destination
  # TODO: Add that stupid IIS HTTP header
  $self->{destination} = $self->{env}->{REQUEST_URI};
  $self->{method} = $self->{env}->{REQUEST_METHOD};
}

sub render_markup {
  my ( $self, $template_file, $template_vars ) = @_;
  my $conf = $self->{config}->{layout};

  my $template = "$conf->{templatepath}/$template_file";
  my %template_vars = %{$template_vars};
  
  my $output;
  
  if ( open( my $fh, "<:encoding(UTF-8)", $template) ) {
    while ( my $row = <$fh> ) {
      chomp $row;
      $output .= $row;
    }
    close( $fh );
  } else {
    Carp::croak( "Could not open $template" );
  }
  
  foreach my $key ( keys \%template_vars ) {
    my $val = $template_vars{$key};
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
    } else {
      Carp::croak( "Could not open $master" );
    }
    
    $master_output =~ s/{yield}/$output/g;
    $output = $master_output;
  }

  $self->logger( 'Rendering output' );

  $self->set_header ( $template_file =~ /\.([a-z]{1,})/ );
  print $output;
}

sub render_txt {
  my ( $self, $txt ) = @_;
  
  print $txt;
}

sub set_header {
  my ( $self, $content_type ) = @_;

  if ( lc $content_type eq 'html' ) {
    print $self->header( -type => 'text/html', -charset => 'utf-8' );
  }
}

sub mapper {
  my $self = shift;
  
  my $router;
  my @params;
  
  foreach my $key ( keys %{ $self->{routes} } ) {
    my $route = $self->{routes}->{$key};
    
    if ( $self->{method} eq $route->{method} &&
      $self->{destination} =~ $route->{pattern} ) {
      
      @params = $self->{destination} =~ $route->{pattern};

      $router = $route;
    }
  }

  # Run hooks
  $self->run_hooks;

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
}

sub run_hooks {
  my $self = shift;
  my $hooks = $self->{config}->{hooks};
  
  $self->logger( 'Running hooks before_each' );
  # Run each subroutine
  $hooks->{before_each}->( $self ) if ref $hooks->{before_each} eq 'CODE';
}

sub build_pattern {
  my ( $self, $pattern ) = @_;
  # Remov method from pattern, substitute it with nothing
  $pattern =~ s/(GET|POST|PUT|DELETE)\s?//i;
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

  return $pattern;
}

sub run {
  my $self = shift;
  
  return $self->mapper();
}

1;