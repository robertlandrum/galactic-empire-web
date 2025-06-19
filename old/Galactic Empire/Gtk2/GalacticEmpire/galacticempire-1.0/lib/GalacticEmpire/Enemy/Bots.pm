package GalacticEmpire::Enemy::Bots;

use Data::Dumper;
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
    type => 'BOTS',
    name => 'Bot',
    names => 'Bots',
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

  
  if($ge->{current_year} == 0) {
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
      next if($p->{id} == $self->{home}->{id});
      my $d = $ge->calc_dsquare($p,$self->{home});
      if($d > 0) {
        push(@moves,{
          weight => $d,
          planet => $p
        });
        @moves = (sort { $a->{weight} <=> $b->{weight} } @moves)[0,1,2,3,4,5];
      }
    }
    for my $move (@moves) {
      next unless($move->{planet});
      $ge->add_transport(
        $self->{home},
        $move->{planet},
        15
      );
    }
    $self->{enemy_type} = "INDEPENDENT";
    return;
  }

  # pick an enemy every 8 years
  # ---------------------------
  if(($ge->{current_year} % 80) == 0) {
    $self->pick_enemy();
  }

  # remainder of the game logic
  # ---------------------------
  for my $p (@{$ge->{planets}}) {
    next if($p->{owner} eq "NOPLANET");
    next unless($p->{owner} eq "BOTS");

    # Home planet strategy
    # --------------------
    if($p->{homeplanet}) {
      # do 4 moves
      # ----------
      my @moves = (
        { weight => 0, planet => undef },
        { weight => 0, planet => undef },
        { weight => 0, planet => undef },
        { weight => 0, planet => undef },
      );

      for my $tp (@{$ge->{planets}}) {
        next if($tp->{owner} eq "NOPLANET");
        next if($p->{id} == $tp->{id});

        # Ignore anything that isn't our enemy after year 90
        # --------------------------------------------------
        next if(
          $ge->{current_year} > 90 && 
          $tp->{owner} ne "BOTS" && 
          $tp->{owner} ne $self->{enemy_type}
        );

        my $d = $ge->calc_dsquare($p,$tp);

        $d = int($d / 36);
        $d = 1 if($d < 1);
        $d = 7 if($d > 7);

        my $weight = 0;
        if(defined $self->{enemy} && 
          $tp->{id} == $self->{enemy}->{home}->{id} && 
          $p->{ships} > ($tp->{ships} * 2)
        ) {
          $weight += 3;
        }

        if($tp->{owner} eq "INDEPENDENT" && $ge->{current_year} < 100) {
          $weight += 2;
        }
        if($tp->{owner} eq $self->{enemy_type}) {
          $weight += ($d < 2) ? 9 : 4;
        }
        
        if($tp->{owner} eq "BOTS") {
          if($tp->{industry} > 3 && $d > 1) {
            $weight += 7;
          }
          else {
            if($ge->{current_year} < 80) {
              $weight++;
            }
          }
        }

        # Closer items will have higher weights
        # -------------------------------------
        $weight = ($weight * (36 + $ge->{current_year}/5)) / $d;
        $weight += get_rand(15);

        if($weight > 0) {
          push(@moves,{
            weight => $weight,
            planet => $tp
          });
          @moves = (sort { $b->{weight} <=> $a->{weight} } @moves)[0,1,2,3];
        }
      }


      # Divy up 2/3 of our ships
      # ------------------------
      my $ship_pool = int(($p->{ships} * 2) / 3);
      if($ship_pool > 80) {
        my @ship_moves = ();
        my $mcnt = get_rand(2) + 2;
        $mcnt = 1 if($mcnt > 3);
        for(my $j = 0; $j < $mcnt; $j++) { # bug?
          my $move = $moves[$j];
          next unless($move->{planet});
          next unless($move->{weight} > 0);
          my $ships_to_move = 0;
          if($move->{planet}->{owner} ne "BOTS") {
            if($ge->get_owned($move->{planet},"BOTS") ||
              $move->{planet}->{homeplanet}
            ) {
              # Make sure we send enough ships to take it
              # -----------------------------------------
              $ships_to_move = int(($move->{planet}->{ships} * 3) / 2);
            }
            else {
              # Pretend like we can take it
              # ---------------------------
              $ships_to_move = 10 + int($ge->{current_year}/3);
              $ships_to_move = 150 if($ships_to_move > 150);
            }
          }
          else {
            # It's one of ours
            # ----------------
            $ships_to_move = int($ship_pool / $mcnt);
          }

          if($ships_to_move > 0 && $ships_to_move < $ship_pool) {
            # Even though the original code sent ships here, I
            # believe it's broken.  I believe the intention is to determine
            # a base number of ships to send.  Later, we will divy up
            # anything left in the pool and fire them off.
            # -------------------------------------------------------------
            #$ge->add_transport(
            #  $p,
            #  $move->{planet},
            #  $ships_to_move
            #);
            $move->{ships} = $ships_to_move;
            $ship_moves[$j] = $move;

            $ship_pool -= $ships_to_move;
          }

        }


        # I believe the intention here is to send a "followup" wave
        # ---------------------------------------------------------
        for (my $j = 3; $j >= 0; $j--) {
          my $ships_to_move = $ship_pool ? int($ship_pool / ($j + 1)) : 0;
          my $tp = $moves[$j]->{planet};
          next unless($tp);

          # See if we found any ships worth moving in the previous step
          # -----------------------------------------------------------
          if($ship_moves[$j]->{ships} > 0) {
            # Add these "stragglers" to the pool
            # ----------------------------------
            my $s = $ships_to_move + $ship_moves[$j]->{ships};
            $ge->add_transport(
              $p,
              $tp,
              $s
            );
            $ship_pool -= $ships_to_move;
          }
        }
      }
      next;
    }
    next if(get_rand(2));

    # not a home planet
    # -----------------
    my @moves = (
      { weight => 0, planet => undef },
      { weight => 0, planet => undef },
      { weight => 0, planet => undef },
      { weight => 0, planet => undef },
    );
    for my $tp (@{$ge->{planets}}) {
      next if($tp->{owner} eq "NOPLANET");
      next if($tp->{owner} eq "INDEPENDENT" && $ge->{current_year} > 90);
      next if($p->{id} == $tp->{id});

      my $d = $ge->calc_dsquare($p,$tp);
      $d = int($d / 25);
      $d = 1 if($d < 1);
      $d = 6 if($d > 5);
     
      my $weight = 0;

      if(defined $self->{enemy} && 
        $tp->{id} == $self->{enemy}->{home}->{id} && 
        $tp->{ships} < (2 * $p->{ships})
      ) {
        $weight += 2;
      }
      if($tp->{owner} eq "INDEPENDENT") {
        $weight++;
      }
      if($tp->{owner} eq $self->{enemy_type}) {
        $weight += 5;
      }

      if($tp->{id} != $self->{home}->{id} &&
        $tp->{owner} eq "BOTS" &&
        $tp->{industry} > $p->{industry}
      ) {
        $weight += ($tp->{industry} - $p->{industry});
      }

      if($tp->{id} == $self->{home}->{id}) {
        if($tp->{owner} ne "BOTS") {
          $weight += 10;
        }
        elsif($ge->{current_year} > 90 && $d < 2) {
          $weight += 3;
        }
        else {
          $weight++;
        }
      }

      # Closer planets have higher weights
      # ----------------------------------
      $weight = int(($weight * 25) / $d);
      $weight += get_rand(10);

      if($weight > 0) {
        push(@moves,{
          weight => $weight,
          planet => $tp
        });
        @moves = (sort { $b->{weight} <=> $a->{weight} } @moves)[0,1,2,3];
      }
    }


    my $ship_pool = $p->{industry} ? int(($p->{ships} * 3) / 4) : $p->{ships};

    if($ship_pool > int($ge->{current_year} / 4) || $ship_pool > 30) {
      my $mcnt = get_rand(3) + 1;
      $mcnt = 1 if($mcnt > 3);
      for (my $j = 0; $j < $mcnt; $j++) {
        my $move = $moves[$j];
        next unless($move->{planet});
        next unless($move->{weight});
        my $ships_to_move = 0;
        if($move->{planet}->{owner} ne "BOTS") {
          if($ge->get_owned($move->{planet},"BOTS") ||
            $move->{planet}->{homeplanet}
          ) {
            $ships_to_move = int(($move->{planet}->{ships} * 3) / 2);
          }
          else {
            $ships_to_move = 10 + int($ge->{current_year} / 3);
            $ships_to_move = 80 if($ships_to_move > 80);
          }
        }
        else {
          $ships_to_move = int($ship_pool / $mcnt);
        }
        if($ships_to_move && $ships_to_move < $ship_pool) {
          $move->{ships} = $ships_to_move;
          $ship_pool -= $ships_to_move;
        }
      }
      for(my $j = $mcnt; $j >= $mcnt; $j--) {
        my $ships_to_move = int($ship_pool / ($j + 1));
        my $move = $moves[$j];
        next unless($move->{planet});
        next unless($move->{weight});
        next unless($move->{ships});
        $ship_pool -= $ships_to_move;
        $ships_to_move += $move->{ships};
        $ge->add_transport(
          $p,
          $move->{planet},
          $ships_to_move
        );
      }
    }
  }
}
sub pick_enemy {
  my $self = shift;
  $self->pick_enemy_closest();
}

1;
