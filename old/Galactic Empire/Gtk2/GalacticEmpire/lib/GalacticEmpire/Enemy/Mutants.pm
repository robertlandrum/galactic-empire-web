package GalacticEmpire::Enemy::Mutants;

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
    type => 'MUTANTS',
    name => 'Mutant',
    names => 'Mutants',
    enemy => undef,
    enemy_type => undef,
    planet_count => 0,
    home => undef,
    stage => undef,
#    debug => 1,
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

  if($ge->{current_year} == 0) {
    $self->pick_enemy();
    $self->{planet_count} = 1;

    $self->get_n_planets(6,15);
    return;
  }

  my $count = $self->planet_count();

  if($count > $self->{planet_count}) {
    $agress = 1;
  }

  if($count < $self->{planet_count}) {
    $agress = -1;
  }
  $self->{planet_count} = $count;

  # see if our enemy is dead
  # ------------------------
  if($self->{enemy}->{dead}) {
    # they're dead, get new enemy
    # ---------------------------
    while($self->{enemy}->{dead}) {
      $self->pick_enemy();
    }
  }

  # check to reassign mutant staging planet close to enemy home planet
  # ------------------------------------------------------------------
  if($self->{stage}) {
    my $w = 9999;
    my $stage;
    for my $p (@{$ge->{planets}}) {
      next if($p->{owner} eq "NOPLANET");
      if($self->is_ours($p) && $ge->get_owned($p,$self->{enemy_type})) {
        my $d = $ge->calc_dsquare($p,$self->{enemy}->{home});
        if($d < $w) {
          $stage = $p;
          $w = $d;
        }
      }
    }
    if($w < 9999) {
      $self->{stage} = $stage;
    }
  }

  # early year game logic
  # ---------------------
  if($ge->{current_year} < 90) {
    if($self->is_ours($self->{home})) {
      # 4 moves
      # -------
      my @moves = (
        { weight => 0, planet => undef },
        { weight => 0, planet => undef },
        { weight => 0, planet => undef },
        { weight => 0, planet => undef },
      );

      for my $p (@{$ge->{planets}}) {
        next if($p->{owner} eq "NOPLANET");
        next if($self->is_ours($p));
        next if($p->{id} == $self->{home}->{id});

        my $d = $ge->calc_dsquare($self->{home},$p);
        my $weight = 0;
        if($agress < 0) {
          $weight = ($p->{owner} ne "INDEPENDENT");
          $weight = int(($weight * 60) / $d);
        }
        elsif($agress == 0) {
          $weight = (
            ($p->{owner} eq $self->{enemy_type}) ||
            (!$self->is_ours($p) && $ge->get_owned($p,"MUTANTS"))
          ) ? 2 : 1;
          $weight = int(($weight * (120 + int($ge->{current_year} / 2))) / $d);
        }
        elsif($agress > 0) {
          $weight = ($p->{owner} eq $self->{enemy_type}) ? 2 : 1;
          $weight = int(($weight * (120 + int($ge->{current_year} / 2))) / $d);

        }
        $weight += get_rand(10);

        if($weight > 0) {
          push(@moves,{
            weight => $weight,
            planet => $p
          });
          @moves = (sort { $b->{weight} <=> $a->{weight} } @moves)[0,1,2,3];

        }
      }


      my $ship_pool = $self->{home}->{ships};
      if($agress < 0) {
        $ship_pool = int($ship_pool / 4);
      }
      elsif($agress == 0) {
        $ship_pool = int(($ship_pool * 3) / 5);
      }
      elsif($agress > 0) {
        $ship_pool = int(($ship_pool * 3) / 4);
      }

      $self->process_moves(
        source => $self->{home},
        moves  => \@moves,
        ship_pool => $ship_pool,
        known_threshold_multiplier => 1.33,
        unknown_thresholds         => [
          (20 + int($ge->{current_year} / 3)),
          150
        ],
      );
    }
    else {
      # no home, pick new home
      # ----------------------
      $self->get_new_home();
    }

    # send ships home
    # ---------------
    for my $p (@{$ge->{planets}}) {
      next unless($self->is_ours($p));
      next unless($p->{ships} > 10);
      $ge->add_transport(
        $p,
        $self->{home},
        ($p->{ships} - 6)
      );
    }

    return;
  }

  # late game strategy
  # ------------------
  if($self->is_ours($self->{home})) {
    # 4 moves
    # -------
    my @moves = (
      { weight => 0, planet => undef },
      { weight => 0, planet => undef },
      { weight => 0, planet => undef },
      { weight => 0, planet => undef },
    );

    for my $p (@{$ge->{planets}}) {
      next if($p->{owner} eq "NOPLANET");
      next if($self->is_ours($p));
      next if($p->{id} == $self->{home}->{id});

      if(!$self->{stage} && $p->{owner} eq $self->{enemy_type}) {
        $self->{stage} = $p;
      }

      if($self->{enemy}->{home}->{id} == $p->{id}) {
        if($self->{stage} && 
          $self->{stage}->{owner} ne "MUTANTS" && 
          ($self->{home}->{ships} > (2 * $self->{enemy}->{home}->{ships}))
        ) {
          my $ship_pool = int(($self->{home}->{ships} * 4) / 5);
          if($ship_pool) {
            $ge->add_transport(
              $self->{home},
              $self->{enemy}->{home},
              $ship_pool
            );
          }
        }
        next;
      }
      
      my $weight = 0;
      my $d = $ge->calc_distance($self->{enemy}->{home},$p);
      my $d1 = $ge->calc_distance($self->{home},$p);

      next if($d == 0 || $d1 == 0);
      $d = 2 if($d == 1);

      if($agress < 0) {
        $weight = (!$self->is_ours($p) && $ge->get_owned($p,"MUTANTS")) ? 1 : 0;
        $weight = int(($weight * 100) / $d1);
      }
      elsif($agress == 0) {
        $weight = int((!$self->is_ours($p) && $ge->get_owned($p,"MUTANTS")) * 20 / $d1);
        $weight *= ($p->{industry} == 0) ? 0 : 1;
        $weight += ($p->{id} == $self->{stage}->{id} && $self->is_ours($p)) * 20;
        $weight += ($p->{owner} eq $self->{enemy_type}) * int(20 / $d);
        $weight += ($p->{id} == $self->{stage}->{id} && $self->is_ours($p)) * 1;
      }
      elsif($agress > 0) {
        $weight = (($p->{owner} eq $self->{enemy_type}) * int(24 / $d));
        $weight += ($p->{id} == $self->{stage}->{id} && $self->is_ours($p)) * 10;
      }
      $weight += get_rand(10);

      if($weight > 0) {
        push(@moves,{
          weight => $weight,
          planet => $p
        });
        @moves = (sort { $b->{weight} <=> $a->{weight} } @moves)[0,1,2,3];
      }
    }

    my $ship_pool = $self->{home}->{ships};
    if($agress < 0) {
      $ship_pool = int($ship_pool / 3);
    }
    elsif($agress == 0) {
      $ship_pool = int($ship_pool / 2);
    }
    elsif($agress > 0) {
      $ship_pool = int(($ship_pool * 3) / 5);
    }

    $self->process_moves(
      source => $self->{home},
      moves  => \@moves,
      ship_pool                  => $ship_pool,
      known_threshold_multiplier => 1.33,
      unknown_thresholds         => [
        (20 + int($ge->{current_year} / 3)),
        120
      ],
    );
  }
  else {
    $self->get_new_home();
  }

  # late game other planet moves
  # ----------------------------
  for my $p (@{$ge->{planets}}) {
    next unless($self->is_ours($p));
    next unless($p->{ships});

    if($self->{stage} && $p->{id} == $self->{stage}->{id} && $self->is_ours($self->{stage})) {
      if($self->{enemy}->{home}->{ships} < (2 * $p->{ships})) {
        my $ship_pool = $self->{enemy}->{home}->{ships} * 2;
        if($ship_pool) {
          $ge->add_transport(
            $p,
            $self->{enemy}->{home},
            $ship_pool
          );
        }
      }
      my $weight = 9999;
      my $next_planet = undef;
      for my $p2 (@{$ge->{planets}}) {
        next if($p2->{owner} ne $self->{enemy_type});
        next if($p2->{id} == $self->{stage}->{id});
        if($self->{stage}->{ships} > (2 * $p2->{ships}) ) {
          my $d = $ge->calc_dsquare($self->{stage},$p2);
          if($d < $weight) {
            $weight = $d;
            $next_planet = $p2;
          }
        }
      }
      if($weight < 9999) {
        my $ship_pool = int(($next_planet->{ships} * 3) / 2);
        $ship_pool = 15 if($ship_pool == 0);
        if($ship_pool) {
          $ge->add_transport(
            $self->{stage},
            $next_planet,
            $ship_pool
          );
        }
      }
      next;
    }
    # else 

    my $d = 9999;
    my $d1 = $d;
    if($self->is_ours($self->{home})) {
      $d = $ge->calc_dsquare($self->{home},$p);
    }
    if($self->{stage} && $self->is_ours($self->{stage})) {
      $d1 = $ge->calc_dsquare($self->{stage},$p);
    }
    if($p->{ships} > (10 + int($ge->{current_year} / 20))) {
      my $ship_pool = $p->{ships} - 6;

      my $dest = ($d1 < $d) ? $self->{stage} : $self->{home};
      $ge->add_transport(
        $p,
        $dest,
        $ship_pool
      );
    }
  }
}

sub pick_enemy {
  my $self = shift;
  $self->pick_enemy_randomly();
}

1;
