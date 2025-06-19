package GalacticEmpire::Enemy::Blobs;

use strict;
#use GalacticEmpire;
use base ("GalacticEmpire","GalacticEmpire::Enemy");
sub get_rand {
  goto &GalacticEmpire::get_rand;
}

sub new {
  my $class = shift;
  my $ge = shift;
  my $self = {
    dead => 0,
    type => 'BLOBS',
    name => 'Blob',
    names => 'Blobs',
    enemy => undef,
    enemy_type => undef,
    planet_count => 0,
    home => undef,
  };
  bless($self,$class);
  $self->{ge} = $ge;
  return $self;
}

sub move {
  my $self = shift;
  return if($self->{dead});
  my $ge = $self->{ge};

  for my $p (@{$ge->{planets}}) {
    if($p->{owner} eq "BLOBS") {
      for my $tp (@{$ge->{planets}}) {
        if($tp->{owner} ne "BLOBS" &&
          $tp->{homeplanet} &&
          ($tp->{ships} * 2) < $p->{ships}
        ) {
          next if(get_rand(3) == 0);
          my $ships_to_send = $tp->{ships} * 2;
          $ships_to_send += $self->calc_time($p,$tp);

          # make sure we don't send more than we have
          # -----------------------------------------
          if($ships_to_send < $p->{ships}) {
            $ge->add_transport(
              $p,
              $tp,
              $ships_to_send
            );
          }
        }
      }
    }
  }
} 

1;
