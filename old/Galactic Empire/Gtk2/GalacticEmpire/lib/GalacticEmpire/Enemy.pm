package GalacticEmpire::Enemy;

use strict;
use GalacticEmpire;
for my $func (qw(get_owned get_rand calc_dsquare calc_distance calc_time)) {
  eval qq[
    sub $func {
      goto &GalacticEmpire::$func;
    }
  ];
}


sub pick_enemy_closest {
  my $self = shift;
  my $ge = $self->ge;
  my $weight = 9999;
  my $t;

  for my $p (@{$ge->{planets}}) {
    next if($p->{owner} eq $self->{type});
    next unless($p->{homeplanet});
    my $d = $ge->calc_dsquare($self->{home},$p);
    if($d < $weight) {
      $weight = $d;
      $t = $p->{owner};
    }
  }
  unless($t) {
    $t = "HUMAN";
  }
  $self->{enemy_type} = $t;
  $self->{enemy} = $ge->get_enemy($t);
}

sub pick_enemy_randomly {
  my $self = shift;
  my $e = get_rand(($self->ge->{total_enemies}-1));
  my $t = $self->ge->{enemies}[$e]->{type};
  my $ot = $self->{enemy_type} || '';

  # if we've selected ourselves, select humans
  # ------------------------------------------
  $self->{enemy_type} = ($t eq $self->{type} || $ot eq $t) ? 'HUMAN' : $t;
  $self->{enemy} = $self->ge->get_enemy($t);

}

sub ge {
  return shift->{ge};
}

sub planet_count {
  my $self = shift;
  my $ge = $self->ge;
  my $count = 0;

  for my $p (@{$ge->{planets}}) {
    $count++ if($p->{owner} eq $self->{type});
  }
  return $count;
}

sub can_see_ships {
  my $self = shift;
  my $p = shift;
  return (
    $p->{homeplanet} || $self->ge->get_owned($p,$self->{type})
  );
}

sub is_ours {
  my $self = shift;
  my $p = shift;
  return (
    $p->{owner} eq $self->{type}
  );
}

sub is_our_home {
  my $self = shift;
  my $p = shift;
  return (
    $p->{id} == $self->{home}->{id}
  );
}  

sub process_moves {
  my $self = shift;
  my %params = @_;
  my $source = $params{source};
  my $moves = $params{moves};
  my $ship_pool = $params{ship_pool};
  my $kw_thresh = $params{known_threshold_multiplier};
  my $uk = $params{unknown_thresholds};
  $uk = [$uk] unless(ref($uk));
  my $min_ships = $params{min_ships} || 0;;

  my $move_count = @$moves;

  for (my $i = $move_count; $i >= 0; $i--) {
    my $move = $moves->[$i];
    next unless($move->{planet});
    next if($move->{weight} <= 0);

    # This is a divison algorithm so that it exhausts ship_pool completely
    # --------------------------------------------------------------------
    # n = 61; n/3 = 20; n==41; n/2=20; n==21; n/1=21; n==0;
    my $ships_avail = int($ship_pool / ($i + 1));

    # gotta have ships to send
    # ------------------------
    print "Ships to send: $ships_avail <= $min_ships\n" if($self->{debug});
    next if($ships_avail <= $min_ships);

    if($self->can_see_ships($move->{planet})) {
      # check to see if we can take them
      # --------------------------------
      my $x = int($move->{planet}->{ships} * $kw_thresh);
      print "Takeable Planet Ships: $ships_avail < $x\n" if($self->{debug});
      next if($ships_avail < $x);
    }
    else {
      # skip if we can't make minimums
      # ------------------------------
      my $failed = 0;
      for my $t (@$uk) {
        print "Check Minimum: $ships_avail < $t\n" if($self->{debug});
        $failed++ if($ships_avail < $t);
      }
      #next if($failed);  # Makes for interesting opponents
      next if($failed == @$uk); # Mindless sheep who attack no matter what
    }

    if($self->{debug}) {
      print "Adding Move: $ships_avail\n";
      use Data::Dumper;
      print Dumper($move->{planet});
    }
    $self->ge->add_transport(
      $source,
      $move->{planet},
      $ships_avail,
    );
    $ship_pool -= $ships_avail;
  }
}

sub get_new_home {
  my $self = shift;
  my $ge = $self->ge;
  my $max_industry = 0;
  for my $p (@{$ge->{planets}}) {
    if($self->is_ours($p) && $p->{industry} > $max_industry) {
      $max_industry = $p->{industry};
      $self->{home} = $p;
    }
  }
}

# Simple function for planning out some initial planets to take.
# --------------------------------------------------------------
sub get_n_planets {
  my $self = shift;
  my $count = shift || 6;
  my $ships_to_send = shift || 15;
  my $ge = $self->ge;

  my $max = $count - 1;

  # Map out N dummy planets with a high weight.
  # -------------------------------------------
  my @moves = map { 
    { weight => 9999, planet => undef }
  } (0..$max);

  # Iterate over planets.  As lower weight planets are added to @moves
  # the lowest N weighted planets are added.
  # ------------------------------------------------------------------
  for my $p (@{$ge->{planets}}) {
    next if($p->{owner} eq "NOPLANET");
    next if($p->{id} == $self->{home}->{id});

    my $d = $ge->calc_dsquare($self->{home},$p);
    my $weight = $d;

    if($weight > 0) {
      push(@moves,{
        weight => $weight,
        planet => $p
      });
      # get closest planets
      # -------------------
      @moves = (sort { $a->{weight} <=> $b->{weight} } @moves)[0..$max];
    }
  }
  for my $move (@moves) {
    next unless($move->{planet} && $move->{weight});
    $ge->add_transport(
      $self->{home},
      $move->{planet},
      $ships_to_send
    );
  }
}
1;
