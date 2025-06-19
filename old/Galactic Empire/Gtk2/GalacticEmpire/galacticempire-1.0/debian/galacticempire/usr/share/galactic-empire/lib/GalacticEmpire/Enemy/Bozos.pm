package GalacticEmpire::Enemy::Bozos;

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
    type => 'BOZOS',
    name => 'Bozo',
    names => 'Bozos',
    enemy => undef,
    enemy_type => undef,
    home => undef,
    search => [],
    next => undef,
    stage => undef,
    wait  => 9999,
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
    $self->{stage} = $self->{home};
    $self->{wait} = 9999;

    # Get 6 closest planets to use as producers
    # -----------------------------------------
    $self->get_n_planets(6,15);

    return;
  }

  if($self->{next} && $self->is_ours($self->{next})) {
    $self->{stage} = $self->{next};
    $self->{next} = undef;
    $self->{wait} = 9999;
  }

  # We need to check to make sure stage is ours or else
  # we end up stealing ships (in old version we did, in new
  # version, we just launch other peoples ships)
  # -------------------------------------------------------
  if($self->{stage} && !$self->is_ours($self->{stage})) {
    # Bummer.  Our stage was lost.
    # We need to pick a new stage
    # Let's pick the planet with the most ships
    # -----------------------------------------
    my $w = 0;
    for my $p (@{$ge->{planets}}) {
      if($self->is_ours($p) && $p->{ships} > $w) {
        $self->{stage} = $p;
        $w = $p->{ships};
      }
    }
  }

  # It's possible we don't own any planets at this time
  # (because we're in flight), so don't make any moves 
  # until we own something
  # ---------------------------------------------------
  return unless($self->is_ours($self->{stage}));

  # late game strategy
  # ------------------
  my $enemy = undef;
  if($ge->{current_year} > 180) {
    my $d = 0;
    my $weight = 0;

    # Whichever of our enemies owns more of our planets, they are our enemy
    # ---------------------------------------------------------------------
    for my $e (@{$ge->{enemies}}) {
      for my $p (@{$ge->{planets}}) {
        next if($p->{owner} eq "NOPLANET");
        if($ge->get_owned($p,"BOZOS") && $e->is_ours($p)) {
          $weight++;
        }
      }
      if($weight > $d) {
        $enemy = $e->{type};
        $d = $weight;
      }
    }

    if($d > 0) {
      for my $p (@{$ge->{planets}}) {
        next if($p->{owner} eq "NOPLANET");

        if($p->{owner} eq $enemy && 
          $p->{homeplanet} && 
          $self->{stage}->{ships} > (2 * $p->{ships})
        ) {
          # send ships
          # ----------
          $ge->add_transport(
            $self->{stage},
            $p,
            $self->{stage}->{ships}
          );
          last;
        }
      }
    }
    unless(defined $enemy) {
      $enemy = "INDEPENDENT";
    }
  }
  else {
    $enemy = "INDEPENDENT";
  }

  # I believe we need to check to see if stage is ours here.
  # --------------------------------------------------------
  if($self->{wait} == 9999 && !$self->{next} && $self->{stage}->{ships} >= 5) {
    my @moves = (
      { weight => 0, planet => undef },
      { weight => 0, planet => undef },
      { weight => 0, planet => undef },
      { weight => 0, planet => undef },
      { weight => 0, planet => undef },
    );
    # Calculate 5 nearest targets, with enemy planets having priority
    # ---------------------------------------------------------------
    for my $p (@{$ge->{planets}}) {
      next if($p->{owner} eq "NOPLANET");
      next if($p->{owner} eq "BOZOS");
      next if($p->{id} == $self->{stage}->{id});

      my $d = $ge->calc_dsquare($self->{stage},$p);

      if($p->{owner} ne $enemy) {
        $d *= 10;
      }
      if($d > 0) {
        push(@moves,{
          weight => $d,
          planet => $p
        });
        @moves = (sort { $a->{weight} <=> $b->{weight} } @moves)[0,1,2,3,4];
      }
    }
    my $weight = 0;
    for my $i (0..$#moves) {
      next unless($moves[$i]->{planet});
      
      # Save this planet for later, as possible attack from a staging
      # planet.
      # -------------------------------------------------------------
      $self->{search}->[$i] = $moves[$i]->{planet};

      # Calculate time to destintation
      # ------------------------------
      my $time = $ge->calc_time($self->{stage},$moves[$i]->{planet});

      # Set the weight to the max distance
      # ----------------------------------
      if($time > $weight) {
        $weight = $time;
      }
      # Ping the planet
      # ---------------
      if($self->{stage}->{ships}) {
        $ge->add_transport(
          $self->{stage},
          $moves[$i]->{planet},
          1
        );
      }
    }

    # Adjust the wait time (time to arrival + 1 year)
    # -----------------------------------------------
    $self->{wait} = int(($weight + 10) / 10);
  }

  # home planet logic
  # -----------------
  if($self->{stage}->{id} != $self->{home}->{id}) {
    if($self->is_ours($self->{home})) {

      # Move ships from our home to our stage
      # -------------------------------------
      my $ship_pool = $self->{home}->{ships} - (25 + int($ge->{current_year} / 20));
      if($ship_pool > 15) {
        $ge->add_transport(
          $self->{home},
          $self->{stage},
          $ship_pool
        );
      }
    }
  }

  # staging planet logic
  # --------------------
  if($self->{wait} != 9999) {

    # Count down years until our ping arrives at it's furthest destination
    # --------------------------------------------------------------------
    $self->{wait}--;
  }

  if($self->{wait} <= 0) {
    my $move = undef;
    my $j = 0;
    my $found = 0;
    my $w = 9999;

    # For each of our pinged hosts, see if we own it, and if not 
    # see if we can take it
    # ----------------------------------------------------------
    for my $p (@{$self->{search}}) {
      if(!$self->is_ours($p)) {
        if($p->{ships} > $j &&
          ($p->{ships} < int((2 * $self->{stage}->{ships}) / 3))
        ) {
          $move = $p;
          $j = $p->{ships};
          $found = 1;
        }
      }
    }

    # If we found none we didn't own or couldn't take, find the one with
    # the fewest ships
    # ------------------------------------------------------------------
    if(!$found) {
      for my $p (@{$self->{search}}) {
        if(!$self->is_ours($p) && $p->{ships} < $w) {
          $w = $p->{ships};
          $move = $p;
          $found = 1;
        }
      }
    }

    # If we still haven't found a target, Move all staging ships to the
    # Nearest of the pinged planets
    # -----------------------------------------------------------------
    if(!$found) {
      if($self->{stage}->{ships}) {
        $self->{next} = $self->{search}->[0];
        if($self->{next}) {
          $ge->add_transport(
            $self->{stage},
            $self->{next},
            $self->{stage}->{ships}
          );
        }
      }
    }
    else {
      # We've found a target...  Send the stage after them
      # --------------------------------------------------
      if(!$self->is_ours($move) && $self->{stage}->{ships} > int((3 * $move->{ships}) / 2)) {
        $self->{next} = $move;
        if($self->{stage}->{ships}) {
          $ge->add_transport(
            $self->{stage},
            $self->{next},
            $self->{stage}->{ships}
          );
        }
      }
    }
     
    # every 5th year check to nuke home planet
    # ----------------------------------------
    if(($ge->{current_year} % 50) == 0) {
      for my $p (@{$ge->{planets}}) {
        next if($p->{owner} eq "NOPLANET");
        if($p->{homeplanet} && !$self->is_ours($p) &&
          ($self->{stage}->{ships} > (2 * $p->{ships}))
        ) {
          $ge->add_transport(
            $self->{stage},
            $p,
            $self->{stage}->{ships}
          );
        }
      }
    }
  }

  # other planets logic
  # -------------------
  for my $p (@{$ge->{planets}}) {
    next if(!$self->is_ours($p));
    next if($self->{stage}->{id} == $p->{id});
    next if($self->{home}->{id} == $p->{id});

    # Funnel ships to the stage.
    # -------------------------
    if($p->{ships} > 10) {
      $ge->add_transport(
        $p,
        $self->{stage},
        $p->{ships}
      );
    }
  }
}


1;
