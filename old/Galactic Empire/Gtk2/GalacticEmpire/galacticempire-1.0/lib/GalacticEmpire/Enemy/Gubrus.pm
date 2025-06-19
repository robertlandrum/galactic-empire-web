package GalacticEmpire::Enemy::Gubrus;

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
    type => 'GUBRU',
    name => 'Gubru',
    names => 'Gubrus',
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
  my $gcount = 0;
  my $agress = 0;

  if($ge->{current_year} == 0) {
    $self->pick_enemy();
    $self->{planet_count} = 1;
  }

  # Count our planets
  # -----------------
  $gcount = $self->planet_count();

  # Deterine our level of agression
  # -------------------------------
  if($gcount > $self->{planet_count} || $ge->{current_year} <= 80) {
    # we're gaining planets
    $agress = 1;
  }
  if($gcount < $self->{planet_count}) {
    # we're losing planets
    $agress = -1;
  }
  $self->{planet_count} = $gcount;

  # see if our enemy is dead
  # ------------------------
  if($self->{enemy}->{dead}) {
    # they're dead, get new enemy
    # ---------------------------
    while($self->{enemy}->{dead}) {
      my $e = get_rand($ge->{total_enemies} - 1);
      my $t = $ge->{enemies}[$e]->{type};
      $self->{enemy_type} = ($t eq 'GUBRU') ? 'HUMAN' : $t;
      $self->{enemy} = $ge->get_enemy($t);
    }
  }

  if($self->{home}->{owner} eq "GUBRU") {
    # we're gonna make about 4 moves
    # ------------------------------
    my @moves = (
      { weight => 0, planet => undef },
      { weight => 0, planet => undef },
      { weight => 0, planet => undef },
      { weight => 0, planet => undef },
    );

    for my $p (@{$ge->{planets}}) {
      next if($p->{owner} eq "NOPLANET");
      next if($p->{owner} eq "GUBRU");
      next if($p->{id} == $self->{home}->{id}); # redundant?
      my $d = $ge->calc_dsquare($self->{home},$p);

      my $weight = 0;
      # calculate a weight for each planet
      # ----------------------------------
      if($agress < 0) {
        $weight = ($p->{owner} != 'INDEPENDENT');
        $weight = int(($weight * 40) / $d);
      }
      elsif($agress > 0) {
        $weight = $p->{owner} eq $self->{enemy_type} ? 3 : 1;
        $weight *= $p->{owner} eq "INDEPENDENT" ? 2 : 1;
        $weight = int(($weight * (200 + int($ge->{current_year} / 2))) / $d);
      }
      else {
        # If my enemy owns it, or if I ever owned it
        $weight = (($p->{owner} eq $self->{enemy_type}) ||
          ($p->{owner} ne "GUBRU" && $self->get_owned($p,"GUBRU"))) ? 3 : 1;
        $weight = int(($weight * (80 + int($ge->{current_year} / 2))) / $d);

        # If it's after year 15, don't take anymore independents
        $weight = $weight * (($ge->{current_year} > 150 && $p->{owner} eq "INDEPENDENT") ? 0 : 1);

      }
      $weight += get_rand(5);
      
      # Keep the weights for the 4 highest planets
      # ------------------------------------------
      if($weight > 0) {
        push(@moves,{
          weight => $weight,
          planet => $p
        });
        @moves = (sort { $b->{weight} <=> $a->{weight} } @moves)[0,1,2,3];
      }
    }

    my $ships = $self->{home}->{ships};
    
    my $ship_pool;
    if($agress < 0) {
      $ship_pool = int($ships / 5);
    }
    elsif($agress == 0) {
      $ship_pool = ($ge->{current_year} < 100) ? 
        int(($ships * 3) / 5) : 
        int(($ships * 2) / 5);
    }
    elsif($agress > 0) {
      $ship_pool = ($ge->{current_year} < 100) ? 
        int(($ships * 3) / 4) : 
        int(($ships * 1) / 2);
    }

    $self->process_moves(
      source => $self->{home},
      moves => \@moves,
      ship_pool => $ship_pool,
      known_threshold_multiplier => 1.33,
      unknown_thresholds => [
        (15 + int($ge->{current_year} / 2)),
        150
      ],
    );
  }
  else {
    # hmm...  Our home is gone
    # ------------------------
    my $max_industry = 0;
    for my $p (@{$ge->{planets}}) {
      if($p->{owner} eq "GUBRU" && $p->{industry} > $max_industry) {
        $max_industry = $p->{industry};
        $self->{home} = $p;
      }
    }
  }

  # now lets collect some ships from out outlying planets
  # -----------------------------------------------------
  for my $p (@{$ge->{planets}}) {
    next if($p->{owner} ne "GUBRU");
    next if($p->{id} == $self->{home}->{id});
    my $ship_threshold;
    if($agress < 0) {
      $ship_threshold = 6;
    }
    elsif($agress == 0) {
      $ship_threshold = 15;
    }
    elsif($agress > 0) {
      $ship_threshold = 10;
    }

    if($p->{ships} > $ship_threshold) {
      next if(get_rand(1)); # 1 in 2, do nothing
      my $ships_to_move = $p->{ships} - $ship_threshold;

      if($ships_to_move > $ship_threshold && $ships_to_move) {
        $ge->add_transport(
          $p,
          $self->{home},
          $ships_to_move,
          $ge->calculate_travel_time(
            $p,
            $self->{home},
          )
        );
      }
    }
  }
}

sub pick_enemy {
  my $self = shift;
  $self->pick_enemy_randomly();
}

1;
