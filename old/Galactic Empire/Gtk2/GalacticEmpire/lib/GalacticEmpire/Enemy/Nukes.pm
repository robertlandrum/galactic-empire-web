package GalacticEmpire::Enemy::Nukes;

use strict;
use GalacticEmpire;
use base ("GalacticEmpire::Enemy");
sub get_rand {
  goto &GalacticEmpire::get_rand;
}

sub new {
  my $class = shift;
  my $ge = shift;
  my $self = {
    dead => 0,
    type => 'NUKES',
    name => 'Nuke',
    names => 'Nukes',
    enemy => undef,
    enemy_type => undef,
    planet_count => 0,
    home => undef,
    stage => undef,
    next  => undef,
    ndiv => 0,
  };
  bless($self,$class);
  $self->{ge} = $ge;
  return $self;
}

sub move {
  my $self = shift;
  return if($self->{dead});
  my $ge = $self->{ge};
  my $agress = 0;
  my $ccount = 0;

  if($ge->{current_year} == 0) {
    $self->pick_enemy();

    my @moves = (
      { weight => 9999, planet => undef },
      { weight => 9999, planet => undef },
      { weight => 9999, planet => undef },
      { weight => 9999, planet => undef },
      { weight => 9999, planet => undef },
      { weight => 9999, planet => undef },
    );

    for my $p (@{$ge->{planets}}) {
      next if($p->{owner} eq "NOPLANET");
      if($self->is_ours($p)) {
        $self->{stage} = $p;
        $self->{next} = $p;
        next;
      }
      next if($p->{id} == $self->{home}->{id});
      my $d = $ge->calc_dsquare($p,$self->{home});

      # Keep the weights for the 4 highest planets
      # ------------------------------------------
      if($d < 9999) {
        push(@moves,{
          weight => $d,
          planet => $p
        });
        @moves = (sort { $a->{weight} <=> $b->{weight} } @moves)[0,1,2,3,4,5];
      }
    }

    for my $move (@moves) {
      $ge->add_transport(
        $self->{home},
        $move->{planet},
        15
      );
    }
    $self->{ndiv} = 5;
    return;
  }

  # see if our enemy is dead
  # ------------------------
  if($self->{enemy}->{dead}) {
    # they're dead, get new enemy
    # ---------------------------
    while($self->{enemy}->{dead}) {
      $self->pick_enemy();
    }
  }

  if($self->is_ours($self->{next})) {
    $self->{stage} = $self->{next};
    $self->{bored} = 2; # bug?  
  }
  if($self->is_ours($self->{enemy}->{home})) {
    my $et = $self->{enemy}->{type};
    $self->{home} = $self->{enemy}->{home};
    $self->{stage} = $self->{home};
    $self->{next} = $self->{home};
    my $found = 0;
    $self->pick_enemy();
    for my $p (@{$ge->{planets}}) {
      if($p->{homeplanet} && $p->{owner} eq $self->{enemy_type}) {
        $self->{ndiv} = 4;
        $found = 1;
      }
    }
    unless($found) {
      $self->{enemy_type} = $et;
      $self->{enemy} = $ge->get_enemy($et);
      return;
    }
  }

  if($self->{stage}->{id} == $self->{next}->{id}) {
    # determine next planet
    # ---------------------
    if($self->{ndiv} > 0) {
      my $x = int((($self->{stage}->{col} - $self->{enemy}->{home}->{col}) * ($self->{ndiv} - 1)) / $self->{ndiv});
      $x += $self->{enemy}->{home}->{col};

      my $y = int((($self->{stage}->{row} - $self->{enemy}->{home}->{row}) * ($self->{ndiv} - 1)) / $self->{ndiv});
      $y += $self->{enemy}->{home}->{row};
      $self->{ndiv}--;

      my $weight = 9999;
      for my $p (@{$ge->{planets}}) {
        next if($p->{owner} eq "NOPLANET");
        next if($p->{owner} eq "NUKES");
        my $d = (($p->{row} - $y) * ($p->{row} - $y)) +
          (($p->{col} - $x) * ($p->{col} - $x));

        if($d < $weight) {
          $weight = $d;
          $self->{next} = $p;
        }
      }
    }
    else {
      $self->{next} = $self->{enemy}->{home};
    }

    my $t = $ge->calc_time($self->{next},$self->{stage});
    $self->{wait} = int(($t + 10) / 10);
  }

  # if we lose staging, revert to home
  # ----------------------------------
  if(!$self->is_ours($self->{stage})) {
    $self->{stage} = $self->{home};
  }

  # other years, send to staging planet
  # -----------------------------------
  for my $p (@{$ge->{planets}}) {
    next if($p->{owner} eq "NOPLANET");
    next unless($self->is_ours($p));

    if($p->{id} != $self->{stage}->{id}) {
      # not our staging planet
      # ----------------------
      my $ship_pool = $p->{ships};
      if($p->{id} == $self->{home}->{id}) {
        $ship_pool -= 50 + int($ge->{current_year} / 10);
      }
      else {
        $ship_pool -= 10 + int($ge->{current_year} / 20);
      }
      if($ship_pool > (10 + get_rand(25))) {
        $ge->add_transport(
          $p,
          $self->{stage},
          $ship_pool
        );
      }
    }
    else {
      # stage planet logic
      # ------------------
      if($self->{wait}) {
        $self->{wait}--;
        $ge->add_transport(
          $self->{stage},
          $self->{next},
          1
        );
      }
      else {
        if($self->{next}->{ships} > int((6 * $ge->{current_year}) / 10)) {
          # hmm, too many ships, pick new next planet
          # -----------------------------------------
          $self->{next} = $self->{stage};
          next;
        }

        if(int(($self->{next}->{ships} * 5) / 3) < $self->{stage}->{ships}) {
          # we can take them
          # ----------------
          $ge->add_transport(
            $self->{stage},
            $self->{next},
            $self->{stage}->{ships}
          );
        }
        else {
          # not enough ships
          # ----------------
          $self->{bored}--;
          if($self->{bored} < 0) {
            my $weight = 9999;
            my $move = { weight => 9999, planet => undef };
            for my $p2 (@{$ge->{planets}}) {
              if($p2->{owner} eq $self->{enemy_type}) {
                next if($p2->{id} == $self->{stage}->{id});
                my $d = $ge->calc_dsquare($self->{stage},$p2);
                if($d < $weight) {
                  $weight = $d;
                  $move->{weight} = $weight;
                  $move->{planet} = $p2;
                }
              }
            }
            if($weight < 9999 && $move->{planet}) {
              $self->{bored} = 1;
              $self->{next} = $move->{planet};
              $self->{wait} = int(($move->{weight} + 10) / 10);
            }
          }
        }

      }
    }
  }
}

sub pick_enemy {
  my $self = shift;
  $self->pick_enemy_randomly();
}

1;
