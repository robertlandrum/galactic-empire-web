package GalacticEmpire::Enemy::Arachs;

use strict;
use base ("GalacticEmpire::Enemy");
use GalacticEmpire;
sub get_rand {
  goto &GalacticEmpire::get_rand;
}

sub new {
  my $class = shift;
  my $ge = shift;
  my $self = {
    dead => 0,
    type => 'ARACHS',
    name => 'Arach',
    names => 'Arachs',
    enemy => undef,
    enemy_type => undef,
    planet_count => 0,
    home => undef,
    homelost => 0,
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
  my $acount = 0;

  if($ge->{current_year} == 0) {
    $self->pick_enemy();
    $self->{planet_count} = 1;
  }

  $acount = $self->planet_count();

  if($acount > $self->{planet_count} || $ge->{current_year} <= 80) {
    $agress = 1;
  }

  if($acount < $self->{planet_count}) {
    $agress = -1;
  }
  $self->{planet_count} = $acount;

  # see if our enemy is dead
  # ------------------------
  if($self->{enemy}->{dead}) {
    # they're dead, get new enemy
    # ---------------------------
    while($self->{enemy}->{dead}) {
      $self->pick_enemy();
    }
  }

  if($self->{home}->{owner} eq "ARACHS") {
    # Plan 4 moves
    # ------------
    my @moves = (
      { weight => 0, planet => undef },
      { weight => 0, planet => undef },
      { weight => 0, planet => undef },
      { weight => 0, planet => undef },
    );

    for my $p (@{$ge->{planets}}) {
      next if($p->{owner} eq "NOPLANET");
      next if($p->{owner} eq "ARACHS");
      next if($p->{id} == $self->{home}->{id});

      my $d = $self->calc_dsquare($self->{home},$p);
      my $weight;

      if($agress < 0) {
        $weight = ($p->{owner} ne "INDEPENDENT") * 40 / $d
      }
      elsif($agress == 0) {
        $weight = (($p->{owner} eq $self->{enemy_type}) ||
          ($p->{owner} ne "ARACHS" && $ge->get_owned($p,"ARACHS"))) ? 3 : 1;
        $weight *= ($ge->{current_year} > 90 && $p->{owner} eq "INDEPENDENT") ? 0 : 1;
        $weight = ($weight * (90 + ($ge->{current_year} / 2))) / $d;
      }
      elsif($agress > 0) {
        $weight = ($p->{owner} eq $self->{enemy_type} ? 3 : 1);
        $weight *= ($ge->{current_year} > 90 && $p->{owner} eq "INDEPENDENT") ? 0 : 1;
        $weight = ($weight * (200 + ($ge->{current_year} / 2))) / $d;
      }
      $weight += get_rand(5);

      # Keep the weights for the 4 highest planets
      # ------------------------------------------
      if($weight > 0) {
        push(@moves,{
          weight => $weight,
          planet => $p
        });
        @moves = (sort { $b->{weight} <=> $a->{weight} } @moves)[0,1,2];
      }
    }

    my $ships = $self->{home}->{ships};
    
    my $ship_pool;
    if($agress < 0) {
      $ship_pool = int($ships / 4);
    }
    elsif($agress == 0) {
      $ship_pool = $ge->{current_year} < 100 ? 
        int(($ships * 3) / 5) :
        int(($ships * 1) / 2);
    }
    elsif($agress > 0) {
      $ship_pool = $ge->{current_year} < 100 ? 
        int(($ships * 3) / 4) : 
        int(($ships * 3) / 5);
    }

    $self->process_moves(
      source => $self->{home},
      moves  => \@moves,
      ship_pool => $ship_pool,
      known_threshold_multiplier => 1.33,
      unknown_thresholds => [
        (10 + int($ge->{current_year} / 2)),
        100
      ],
    );
  }
  else {
    # no home
    $self->get_new_home();
    $self->{homelost} = 1;
  }


  # now lets collect some ships from out outlying planets
  # -----------------------------------------------------
  for my $p (@{$ge->{planets}}) {
    next if($p->{owner} ne "ARACHS");
    next if($p->{id} == $self->{home}->{id});
    my $home_threshold;
    my $ext_threshold = 0;
    if($agress < 0) {
      my $j = get_rand(2);
      if($j == 0) {
        $home_threshold = 5;
        $ext_threshold = 0;
      }
      else {
        $home_threshold = $p->{ships};
      }
    }
    elsif($agress == 0) {
      my $j = get_rand(6);
      if($j == 0 || $j == 5) {
        $home_threshold = 10;
      }
      elsif($j == 1) {
        $home_threshold = 20;
      }
      elsif($j == 2) {
        $home_threshold = $p->{ships};
      }
      else {
        $home_threshold = $p->{ships};
        $ext_threshold = $home_threshold - 6;
      }
    }
    elsif($agress > 0) {
      my $j = get_rand(6);
      if($j == 0 || $j == 6) {
        $home_threshold = 10;
      }
      elsif($j == 1) {
        $home_threshold = int(($p->{ships} * 1) / 3);
      }
      elsif($j == 2) {
        $home_threshold = int(($p->{ships} * 2) / 3);
        $ext_threshold = $home_threshold - 10;
      }
      else {
        $home_threshold = $p->{ships};
        $ext_threshold = $home_threshold;
      }
    }

    # $home_threshold is num ships to keep on planet
    # ----------------------------------------------
    if($p->{ships} > $home_threshold) {
      my $ships_to_move = $p->{ships} - $home_threshold;
      next unless($ships_to_move);
      my $d = $ge->calc_dsquare($p,$self->{home});
      if($d < (150 + int($ships_to_move / 5))) {
        $ge->add_transport(
          $p,
          $self->{home},
          $ships_to_move
        );
      }
    }

    if($ext_threshold > 0) {
      my $ship_pool = $ext_threshold;
      my @moves = (
        { weight => 0, planet => undef },
        { weight => 0, planet => undef },
        { weight => 0, planet => undef },
      );
      for my $p2 (@{$ge->{planets}}) {
        next if($p2->{owner} eq "NOPLANET");
        next if($p2->{owner} eq "INDEPENDENT" && $ge->{current_year} > 80);
        next if($p2->{id} == $self->{home}->{id});
        next if($p->{id} == $p2->{id}); # don't send ships to ourself;

        my $d = $self->calc_dsquare($p,$p2);
        next if($d == 0);
        my $weight = 50 / $d;
        $weight += get_rand(5);

        if($weight > 0) {
          push(@moves,{
            weight => $weight,
            planet => $p
          });
          @moves = (sort { $b->{weight} <=> $a->{weight} } @moves)[0,1,2];
        }
      }

      $self->process_moves(
        source => $p,
        moves  => \@moves,
        ship_pool => $ship_pool,
        known_threshold_multiplier => 1.33,
        unknown_thresholds => [
          (15 + int($ge->{current_year} / 3)),
          120
        ],
      );
    }
  }
}

sub pick_enemy {
  my $self = shift;
  $self->pick_enemy_randomly();
}

1;
