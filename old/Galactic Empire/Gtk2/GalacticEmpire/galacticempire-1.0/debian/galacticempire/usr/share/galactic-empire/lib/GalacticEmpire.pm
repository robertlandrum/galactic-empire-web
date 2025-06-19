package GalacticEmpire;

use Data::Dumper;
use strict;
use constant PLANETROWS => 27;
use constant PLANETCOLS => 32;
use constant PLANETWIDTH => 16;
use constant PLANETHEIGHT => 16;

use DBI;

use GalacticEmpire::Enemy::Bots;
use GalacticEmpire::Enemy::Blobs;
use GalacticEmpire::Enemy::Bozos;
use GalacticEmpire::Enemy::Nukes;
use GalacticEmpire::Enemy::Arachs;
use GalacticEmpire::Enemy::Czins;
use GalacticEmpire::Enemy::Gubrus;
use GalacticEmpire::Enemy::Mutants;
our $GE_TABLES = qq[
CREATE TABLE planets (
  id            int,
  x             int,
  y             int,
  row           int,
  col           int,
  owner         text,
  lastvisit     int,
  homeplanet    int,
  everowned     int,
  humanpings    int,
  industry      int,
  ships         int,
  is_feeding    int,
  owned         text
);

CREATE TABLE feeds (
  source        int,
  dest          int

);
CREATE TABLE enemies (
  module        text,
  dead          int,
  names         text,
  name          text,
  enemy_type    text,
  planet_count  int,
  type          text,
  home          int,

  homelost      int,
  next          int,
  stage         int,
  wait          int,
  search        text,
  ndiv          int
);
CREATE TABLE transports (
  source        int,
  dest          int,
  owner         text,
  ships         int,
  ping          int,
  timeleft      int
);

CREATE TABLE galacticempire (
  game_over     int,
  total_planets int,
  total_enemies int,
  current_year  int,
  human_home    int
);

];

# Callbacks:
#   current_year (year)
#   fortify (transport)
#   delay ('short','long')
#   game_won ()
#   game_lost ()
#   attack_setup (transport)
#   attack_update (transport)
#   attackers_win (transport)
#   defenders_win (transport)
#   enemy_dead (enemy)

sub new {
  my $class = shift;
  my $self = {};
  bless($self,$class);
  $self->init_new(@_);
  return $self;
}

sub load {
  my $class = shift;
  my $file = shift;
  my $self = {
    planets => [],
    feeds => [],
    transports => [],
    enemies => [],
    stats => {},
  };

  bless($self,$class);
  
  my $dbh = DBI->connect("dbi:SQLite:dbname=$file");
  
  my $planets = $dbh->selectall_arrayref("SELECT * FROM planets", { Slice => {}});

  for my $p (@$planets) {
    my %owned = ();
    for my $o (split(/\,/,$p->{owned})) {
      $owned{$o} = 1;
    }

    $self->{planets}->[$p->{id}] = $p;
    $self->{planets}->[$p->{id}]->{owned} = \%owned;
  }

  my $feeds = $dbh->selectall_arrayref("SELECT * FROM feeds", { Slice => {}});

  for my $f (@$feeds) {
    push(@{$self->{feeds}},{
      source => $self->{planets}->[$f->{source}],
      dest   => $self->{planets}->[$f->{dest}]
    });
  }

  my $enemies = $dbh->selectall_arrayref("SELECT * FROM enemies", { Slice => {}});

  for my $e (@$enemies) {
    my $enemy = $self->load_enemy($e->{module});
    for my $f (qw(dead names name enemy_type planet_count type home homelost next stage wait search ndiv)) {
      next unless(exists $enemy->{$f});
      my $val;
      if($f =~ /^(home|next|stage)$/) {
        $val = $self->{planets}->[$e->{$f}];
      }
      elsif($f eq "search") {
        $val = [map { $self->{planets}->[$_] } split(/\,/,$e->{$f})];
      }
      else {
        $val = $e->{$f};
      }
      $enemy->{$f} = $val;
    }
  }
  # Remap enemy
  for my $e (@{$self->{enemies}}) {
    if($e->{enemy_type}) {
      for my $my_e (@{$self->{enemies}}) {
        if($my_e->{type} eq $e->{enemy_type}) {
          $e->{enemy} = $my_e;
          last;
        }
      }
    }
  }

  my $transports = $dbh->selectall_arrayref("SELECT * FROM transports", { Slice => {}});
  
  for my $t (@$transports) {
    push(@{$self->{transports}},{
      source   => $self->{planets}->[$t->{source}],
      dest     => $self->{planets}->[$t->{dest}],
      owner    => $t->{owner},
      ships    => $t->{ships},
      ping     => $t->{ping},
      timeleft => $t->{timeleft},
      done     => 0,
    });

  }

  my $ge = $dbh->selectall_arrayref("SELECT * FROM galacticempire", { Slice => {}});

  $self->{game_over} = $ge->[0]->{game_over};
  $self->{total_planets} = $ge->[0]->{total_planets};
  $self->{total_enemies} = $ge->[0]->{total_enemies};
  $self->{current_year} = $ge->[0]->{current_year};
  $self->{humans} = {
    type => 'HUMAN',
    home => $self->{planets}->[$ge->[0]->{human_home}],
    dead => 0,
  };


  $dbh->disconnect;
  return $self;
}

sub save {
  my $self = shift;
  my $file = shift;

  my $dbh = DBI->connect("dbi:SQLite:dbname=$file");
  my @t = map { s/\"//g; $_ } $dbh->tables();
  my %tables = map { $_ => 1 } (@t);
  for my $sql (split(/\;/,$GE_TABLES)) {
    next if($sql =~ /^\s*$/s);
    if($sql =~ /create table (\S+)/i) {
      if($tables{$1}) {
        $dbh->do("DELETE FROM $1");
        next;
      }
    }
    # else  
    $dbh->do($sql);
  }
  $dbh->do("INSERT INTO galacticempire (game_over,total_planets,total_enemies,current_year,human_home) VALUES (?,?,?,?,?)",{},
    $self->{game_over},
    $self->{total_planets},
    $self->{total_enemies},
    $self->{current_year},
    $self->{humans}->{home}->{id}
  );

  for my $p (@{$self->{planets}}) {
    $dbh->do("INSERT INTO planets (id,x,y,row,col,owner,lastvisit,homeplanet,everowned,humanpings,industry,ships,is_feeding,owned) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)",{},
      $p->{id},
      $p->{x},
      $p->{y},
      $p->{row},
      $p->{col},
      $p->{owner},
      $p->{lastvisit},
      $p->{homeplanet},
      $p->{everowned},
      $p->{humanpings},
      $p->{industry},
      $p->{ships},
      $p->{is_feeding},
      join(',',keys %{$p->{owned}})
    );
  }
  for my $e (@{$self->{enemies}}) {
    $dbh->do("INSERT INTO enemies (module,dead,names,name,enemy_type,planet_count,type,home,homelost,next,stage,wait,search,ndiv) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)",{},
      ref($e),
      $e->{dead},
      $e->{names},
      $e->{name},
      $e->{enemy_type},
      $e->{planet_count},
      $e->{type},
      $e->{home}->{id},

      $e->{homelost} ? $e->{homelost} : undef,
      $e->{next} ? $e->{next}->{id} : undef,
      $e->{stage} ? $e->{stage}->{id} : undef,
      $e->{wait} ? $e->{wait} : undef,
      join(',',map { $_->{id} } grep { defined $_ } @{$e->{search}}),
      $e->{ndiv} ? $e->{ndiv} : undef
    );

  }
  for my $f (@{$self->{feeds}}) {
    $dbh->do("INSERT INTO feeds (source,dest) VALUES (?,?)",{},
      $f->{source}->{id},
      $f->{dest}->{id}
    );
  }
  for my $t (@{$self->{transports}}) {
    next if($t->{done});
    next unless(defined $t->{source});
    next unless(defined $t->{dest});
    $dbh->do("INSERT INTO transports (source,dest,owner,ships,ping,timeleft) VALUES (?,?,?,?,?,?)",{},
      $t->{source}->{id},
      $t->{dest}->{id},
      $t->{owner},
      $t->{ships},
      $t->{ping},
      $t->{timeleft}
    );
  }

  $dbh->disconnect;
  $self->{gamesaved} = 1;
}

sub init_new {
  my $self = shift;
  my %params = @_;
  $self->{game_over} = 0;
  $self->{total_planets} = PLANETROWS * PLANETCOLS;
  $self->{total_enemies} = 0;
  $self->{planets} = [];
  $self->{transports} = [];
  $self->{feeds} = [];
  $self->{enemies} = [];
  $self->{humans} = {
    type => 'HUMAN',
    home => undef,
    dead => 0,
  };

  for (my $i = 0; $i < $self->{total_planets}; $i++) {
    $self->{planets}[$i] ||= {};
    $self->{planets}[$i]{x} = int(($i % PLANETCOLS)) * PLANETWIDTH;
    $self->{planets}[$i]{y} = int(($i / PLANETCOLS)) * PLANETHEIGHT;
    $self->{planets}[$i]{row} = int($i / PLANETCOLS);
    $self->{planets}[$i]{col} = int($i % PLANETCOLS);
    $self->{planets}[$i]{id} = $i;
    $self->{planets}[$i]{owner} = 'NOPLANET';
    $self->{planets}[$i]{lastvisit} = 0;
    $self->{planets}[$i]{homeplanet} = 0;
    $self->{planets}[$i]{everowned} = 0;
    $self->{planets}[$i]{humanpings} = 0;
    $self->{planets}[$i]{industry} = 0;
    $self->{planets}[$i]{ships} = 0;
    $self->{planets}[$i]{is_feeding} = 0;
    $self->{planets}[$i]{owned} = {};
  }

  for (0..99) {
    my $p = get_rand($self->{total_planets}-1);
    my $prec = $self->{planets}[$p];
    $prec->{owner} = 'INDEPENDENT';
    $prec->{industry} = get_rand(7);
    $prec->{ships} = $prec->{industry};
  }
 
  my @enemies = ();
  if(defined $params{enemies} && @{$params{enemies}}) {
    @enemies = @{$params{enemies}};
  }
  else {
    # 1 8 6 3 4 2 5 7
    @enemies = qw(
      Gubrus
      Czins
      Blobs
      Bots
      Arachs
      Mutants
      Nukes
      Bozos
    );
  }

  for my $e (@enemies) {
    my $class = 'GalacticEmpire::Enemy::'.$e;
    $self->load_enemy($class);
  }
  
  if($self->{total_enemies} == 1) {
    $self->set_home_planet(0,0,11,10,$self->{enemies}[0]);
    $self->set_home_planet(18,20,27,32,$self->{humans});
  }
  elsif($self->{total_enemies} == 2) {
    $self->set_home_planet(0,0,9,10,$self->{enemies}[0]);
    $self->set_home_planet(18,20,27,32,$self->{enemies}[1]);
    $self->set_home_planet(10,11,17,19,$self->{humans});
  }
  elsif($self->{total_enemies} == 3) {
    $self->set_home_planet(0,0,9,10,$self->{enemies}[0]);
    $self->set_home_planet(18,20,27,32,$self->{enemies}[1]);
    $self->set_home_planet(18,0,27,10,$self->{enemies}[2]);
    $self->set_home_planet(10,11,17,19,$self->{humans});
  }
  elsif($self->{total_enemies} == 4) {
    $self->set_home_planet(0,0,9,10,$self->{enemies}[0]);
    $self->set_home_planet(18,20,27,32,$self->{enemies}[1]);
    $self->set_home_planet(18,0,27,10,$self->{enemies}[2]);
    $self->set_home_planet(0,20,9,32,$self->{enemies}[3]);
    $self->set_home_planet(10,11,17,19,$self->{humans});
  }
  elsif($self->{total_enemies} == 5) {
    $self->set_home_planet(0,0,9,10,$self->{enemies}[0]);
    $self->set_home_planet(18,20,27,32,$self->{enemies}[1]);
    $self->set_home_planet(18,0,27,10,$self->{enemies}[2]);
    $self->set_home_planet(0,20,9,32,$self->{enemies}[3]);
    $self->set_home_planet(10,0,17,10,$self->{enemies}[4]);
    $self->set_home_planet(10,11,17,19,$self->{humans});
  }
  elsif($self->{total_enemies} == 6) {
    $self->set_home_planet(0,0,9,10,$self->{enemies}[0]);
    $self->set_home_planet(18,20,27,32,$self->{enemies}[1]);
    $self->set_home_planet(18,0,27,10,$self->{enemies}[2]);
    $self->set_home_planet(0,20,9,32,$self->{enemies}[3]);
    $self->set_home_planet(10,0,17,10,$self->{enemies}[4]);
    $self->set_home_planet(0,11,9,19,$self->{enemies}[5]);
    $self->set_home_planet(10,11,17,19,$self->{humans});
  }
  elsif($self->{total_enemies} == 7) {
    $self->set_home_planet(0,0,9,10,$self->{enemies}[0]);
    $self->set_home_planet(18,20,27,32,$self->{enemies}[1]);
    $self->set_home_planet(18,0,27,10,$self->{enemies}[2]);
    $self->set_home_planet(0,20,9,32,$self->{enemies}[3]);
    $self->set_home_planet(10,0,17,10,$self->{enemies}[4]);
    $self->set_home_planet(0,11,9,19,$self->{enemies}[5]);
    $self->set_home_planet(10,20,18,32,$self->{enemies}[6]);
    $self->set_home_planet(10,11,17,19,$self->{humans});
  }
  elsif($self->{total_enemies} == 8) {
    $self->set_home_planet(0,0,9,10,$self->{enemies}[0]);
    $self->set_home_planet(18,20,27,32,$self->{enemies}[1]);
    $self->set_home_planet(18,0,27,10,$self->{enemies}[2]);
    $self->set_home_planet(0,20,9,32,$self->{enemies}[3]);
    $self->set_home_planet(10,0,17,10,$self->{enemies}[4]);
    $self->set_home_planet(0,11,9,19,$self->{enemies}[5]);
    $self->set_home_planet(10,20,18,32,$self->{enemies}[6]);
    $self->set_home_planet(19,11,27,20,$self->{enemies}[7]);
    $self->set_home_planet(10,11,17,19,$self->{humans});
  }

  $self->{current_year} = 0;
  $self->{gamesaved} = 1;
}

sub add_feed {
  my $self = shift;
  my $source = shift;
  my $dest = shift;

  $self->remove_feed($source);

  # add new feed
  # ------------
  push(@{$self->{feeds}},{
    source => $source,
    dest   => $dest,
  });
}

sub remove_feed {
  my $self = shift;
  my $source = shift;

  # remove any existing feeds from this source
  # ------------------------------------------
  for my $i (0..$#{$self->{feeds}}) {
    if($self->{feeds}[$i]->{source}->{id} == $source->{id}) {
      delete $self->{feeds}[$i];
    }
  }
}

sub calculate_travel_time {
  my $self = shift;
  my $source = shift;
  my $dest = shift;
 
  my $rowcnt = $source->{row} - $dest->{row};
  #$rowcnt *= -1 if($rowcnt < 0);  # redundant?
  $rowcnt *= $rowcnt;

  my $colcnt = $source->{col} - $dest->{col};
  #$colcnt *= -1 if($colcnt < 0);  # redundant?
  $colcnt *= $colcnt;

  # (a * a) + (b * b) = (c * c)
  # ---------------------------
  my $distance = sqrt($rowcnt + $colcnt);

  # each row/col is equal to 0.35 years
  # -----------------------------------
  my $time = $distance * 0.35;

  # and all years are represented as ints, to avoid float problems
  # --------------------------------------------------------------
  my $ret = int($time * 10.0);

  $self->{current_time} = $ret;
  return $ret;
}

sub cheat_lost_game {
  my $self = shift;
  my $enemy = shift;
  for my $t ($self->active_transports()) {
    $t->{owner} = $enemy if($t->{owner} eq "HUMAN");
  }
  for my $p (@{$self->{planets}}) {
    $p->{owner} = $enemy if($p->{owner} eq "HUMAN");
  }
}
sub cheat_own_enemy {
  my $self = shift;
  my $enemy = shift;
  for my $t ($self->active_transports()) {
    $t->{owner} = "HUMAN" if($t->{owner} eq $enemy);
  }
  for my $p (@{$self->{planets}}) {
    $p->{owner} = "HUMAN" if($p->{owner} eq $enemy);
  }
}

sub load_enemy {
  my $self = shift;
  my $class = shift;
  my $fp = $class.".pm";
  $fp =~ s/\:\:/\//g;
  unless($INC{$fp}) {
    # not already loaded
    # ------------------
    eval {
      require $class;
    };
  }
  my $enemy = $class->new($self);
  push(@{$self->{enemies}},$enemy);
  $self->{total_enemies}++;
  return $enemy;
}

sub get_rand {
  my $max = shift;
  $max++;
  my $r = int(rand(time) % $max);
  return $r;
}

sub set_home_planet {
  my $self = shift;
  my $minrow = shift;
  my $mincol = shift;
  my $maxrow = shift;
  my $maxcol = shift;
  my $enemy = shift;

  my $found = 0;

  while(!$found) {
    my $pcol = get_rand(($maxcol-$mincol)-1)+$mincol;
    my $prow = get_rand(($maxrow-$minrow)-1)+$minrow;
    my $id = ($prow * PLANETCOLS) + $pcol;

    if($self->{planets}[$id]->{owner} eq "NOPLANET") {
      # use this as the home planet.
      # ----------------------------
      $enemy->{home} = $self->{planets}[$id];
      $enemy->{home}->{owner} = $enemy->{type};
      $enemy->{home}->{ships} = 100;
      $enemy->{home}->{industry} = 10;
      $enemy->{home}->{homeplanet} = 1;
      if($enemy->{home}->{owner} eq "HUMAN") {
        $enemy->{home}->{humanpings} = 3;
      }
      $self->set_owned($enemy->{home},$enemy->{type});
      $found = 1;
    }
  }
}

sub add_transport {
  my $self = shift;
  my $source = shift;
  my $dest = shift;
  my $ships = shift;
  my $timeleft = shift || $self->calculate_travel_time($source,$dest);

  return unless($ships);
  return unless($source->{ships} >= $ships);
  return if($source->{id} == $dest->{id});
  
  # deduct ships from source
  $source->{ships} -= $ships;

  push(@{$self->{transports}},{
    source   => $source,
    dest     => $dest,
    owner    => $source->{owner},
    ships    => $ships,
    ping     => ($ships == 1 ? 1 : 0),
    timeleft => $timeleft,
    done     => 0,
  });

}

sub do_battle {
  my $self = shift;
  return if($self->{game_over});

  # Update game saved
  # -----------------
  $self->{gamesaved} = 0;

  # process all continuous feeds
  # ----------------------------
  for my $feed (@{$self->{feeds}}) {
    if($feed->{source}->{owner} eq "HUMAN") {
      $self->add_transport(
        $feed->{source},
        $feed->{dest},
        $feed->{source}->{ships}
      );
    }
    else {
      $self->remove_feed($feed->{source});
    }
  }

  # now move the enemies
  # --------------------
  for my $e (@{$self->{enemies}}) {
    $e->move();
  }

  # for each tenth of a year, do some stuff
  # ---------------------------------------
  for (my $tick = 0;$tick < 10;$tick++) {
    $self->{current_year}++;
    # call update time callback
    $self->call_callback('current_year',$self->{current_year});

    # See if any ships have arrived at their destinations
    # ---------------------------------------------------
    for my $i (0..$#{$self->{transports}}) {
      my $transport = $self->{transports}[$i];
      next if($transport->{done});
      $transport->{timeleft}--;
      if($transport->{timeleft} <= 0) {
        # We're here!!!
        # -------------
        if($transport->{owner} eq $transport->{dest}->{owner}) {
          # We own destination.  Fortify position.
          # --------------------------------------
          $self->do_fortify($transport);
        }
        else {
          # battle
          $self->do_attack($transport);
        }
        $transport->{done} = 1;
        #delete $self->{transports}[$i];
      }
    }


    # See if there are any newly dead enemies
    # ---------------------------------------
    for my $e (@{$self->{enemies}}) {
      if($self->check_for_dead($e)) {
        # call enemy dead callback
        $self->call_callback('enemy_dead',$e);
      }
    }

    # See if we have won or lost the game
    # -----------------------------------
    if($self->won_game()) {
      # call win callback
      $self->{game_over} = 1;
      $self->call_callback('game_won');
      return;
    }
    if($self->lost_game()) {
      # call lose callback
      $self->{game_over} = 1;
      $self->call_callback('game_lost');
      return;
    }

  }

  # Now bump everyones ship counts
  # ------------------------------
  for my $p (@{$self->{planets}}) {
    next if($p->{owner} eq "NOPLANET");
    $p->{ships} += $p->{industry};
  }
  $self->generate_stats();
}

sub generate_stats {
  my $self = shift;
  $self->{stats}->{year_end} ||= [];
  my $yr = $self->{stats}->{year_end};

  for my $e (@{$self->{enemies}},{type => 'HUMAN'}) {
    my $industry = 0;
    my $ships = 0;
    my $ships_if = 0;
    my $ships_id = 0;
    my $planets = 0;
    for my $p (@{$self->{planets}}) {
      next unless($p->{owner} eq $e->{type});
      $industry += $p->{industry};
      $ships += $p->{ships};
      $ships_id += $p->{ships};
      $planets++;
    }
    for my $t (@{$self->{transports}}) {
      next if($t->{done});
      next unless($t->{owner} eq $e->{type});
      $ships += $t->{ships};
      $ships_if += $t->{ships};
    }

    push(@$yr,{
      name => $e->{type},
      year => $self->{current_year},
      industry => $industry,
      planets => $planets,
      ships => $ships,
      ships_in_flight => $ships_if,
      ships_in_defense => $ships_id,
    });
  }
}

sub do_fortify {
  my $self = shift;
  my $transport = shift;
  $transport->{dest}->{ships} += $transport->{ships};
  # call fortify callback
  $self->call_callback('fortify',$transport);
}

sub do_attack {
  my $self = shift;
  my $transport = shift;
  my $dest = $transport->{dest};
  my $attack_ships = $transport->{ships};
  my $defend_ships = $dest->{ships};
  

  if($transport->{ships} == 1) {
    $transport->{ping} = 1;
    if($transport->{owner} eq "HUMAN") {
      $self->{stats}->{human_total_pings}++;
    }
  }
  
  # 1 in 5 attacks is a surprise
  # ----------------------------
  my $surprise = (get_rand(5) == 0) ? 1 : 0;
  $transport->{surprise} = $surprise;

  # call to attack setup callback
  $self->call_callback('attack_setup',$transport);

  # time to do battle
  # -----------------
  if($dest->{ships}) {
    # It's a fight to the death
    # -------------------------
    my @firing_order = $surprise ? ($transport,$dest) : ($dest,$transport);
    my $volley = 0;
    while($transport->{ships} && $dest->{ships}) {
      for my $fleet (@firing_order) {
        $volley++;

        my $ships = $fleet->{ships};
        last unless($ships);
        # Only 70-100% of ships fire
        # --------------------------
        my $ships_to_fire = int($ships * ((70 + get_rand(30)) / 100));

        if($fleet->{owner} eq "HUMAN") {
          $self->{stats}->{human_attack_ratio_ships} += $ships;
          $self->{stats}->{human_attack_ratio_firing} += $ships_to_fire;
        }

        while($ships_to_fire--) {
          # Only a 50% chance of hitting an enemy
          # -------------------------------------
          my $hit = get_rand(1);
          if($hit) {
            if($fleet->{owner} eq "HUMAN") {
              $self->{stats}->{human_attack_ratio_hit}++;
            }
            $firing_order[$volley % 2]->{ships}--;
            # call to update shipcount callback
            $self->call_callback('attack_update',$transport);

            # No more ships to shoot
            # ----------------------
            last if($firing_order[$volley % 2]->{ships} == 0);
          }
        }
      }
    }
    if($transport->{ships}) {
      # attackers win
      if($dest->{owner} eq "HUMAN") {
        $self->{stats}->{human_planets_lost}++;
      }

      $dest->{owner} = $transport->{owner};
      $dest->{ships} = $transport->{ships};
      if($transport->{owner} eq "HUMAN") {
        $self->{stats}->{planets_taken}++;
        $dest->{humanpings} = 3;
        $dest->{lastvisit} = $self->{current_year};
      }
      $self->set_owned($dest,$transport->{owner});
      # callback for attackers win
      $self->call_callback('attackers_win',$transport);
    }
    elsif($dest->{ships}) {
      # defenders win
      if($transport->{owner} eq "HUMAN") {
        $dest->{lastvisit} = $self->{current_year};
        $dest->{humanpings}++ if($dest->{humanpings} < 3);
        unless($transport->{ping}) {
          $self->{stats}->{human_failed_attacks}++;
        }
      }
      if($dest->{owner} eq "HUMAN") {
        $self->{stats}->{human_planets_held}++;
      }
      # callback for defenders win
      $self->call_callback('defenders_win',$transport);
    }
    else {
      # WTF?
    }

  }
  else {
    # no defenders
    # ------------
    $transport->{nofight} = 1;
    $dest->{owner} = $transport->{owner};
    $dest->{ships} = $transport->{ships};
    if($transport->{owner} eq "HUMAN") {
      $dest->{humanpings} = 3;
      $dest->{lastvisit} = $self->{current_year};
      $self->{stats}->{planets_taken}++;
    }
    if($dest->{owner} eq "HUMAN") {
      $self->{stats}->{human_planets_lost}++;
    }
    $self->set_owned($dest,$transport->{owner});
    # callback for attackers win
    # --------------------------
    $self->call_callback('attackers_win',$transport);
  }
}

sub check_for_dead {
  my $self = shift;
  my $enemy = shift;
  return 0 if($enemy->{dead});
  
  for my $t ($self->active_transports()) {
    return 0 if($t->{owner} eq $enemy->{type});
  }
  for my $p (@{$self->{planets}}) {
    return 0 if($p->{owner} eq $enemy->{type});
  }

  # they're dead jim
  # ----------------
  $enemy->{dead} = 1;
  return 1;
}


sub won_game {
  my $self = shift;
  
  for my $t ($self->active_transports()) {
    return 0 if($t->{owner} ne "HUMAN");
  }
  for my $p (@{$self->{planets}}) {
    next if($p->{owner} eq "NOPLANET");
    next if($p->{owner} eq "INDEPENDENT");
    return 0 if($p->{owner} ne "HUMAN");
  }
  return 1;
}

sub lost_game {
  my $self = shift;
  
  for my $t ($self->active_transports()) {
    return 0 if($t->{owner} eq "HUMAN");
  }
  for my $p (@{$self->{planets}}) {
    return 0 if($p->{owner} eq "HUMAN");
  }
  # I'm dead
  # --------
  return 1;
}

sub active_transports {
  my $self = shift;
  return grep { !$_->{done} } @{$self->{transports}};
}

sub get_enemy {
  my $self = shift;
  my $name = shift;

  if($name eq "HUMAN") {
    return $self->{humans};
  }
  for my $e (@{$self->{enemies}}) {
    return $e if($e->{type} eq $name);
  }
  return undef;
}

sub calc_dsquare {
  my $self = shift;
  my $source = shift;
  my $dest = shift;
  return (
    (
      ($source->{col} - $dest->{col}) *
      ($source->{col} - $dest->{col})
    ) +
    (
      ($source->{row} - $dest->{row}) *
      ($source->{row} - $dest->{row}) 
    )
  );
}

sub calc_distance {
  my $self = shift;
  my $source = shift;
  my $dest = shift;
  return sqrt($self->calc_dsquare($source,$dest));
}

sub calc_time {
  my $self = shift;
  my $source = shift;
  my $dest = shift;
  return int(10 * $self->calc_distance($source,$dest) * 0.35);

}

sub set_owned {
  my $self = shift;
  my $planet = shift;
  my $type = shift;
  $planet->{owned}->{$type} = 1;
}

sub get_owned {
  my $self = shift;
  my $planet = shift;
  my $type = shift;
  return 0 unless(defined $planet->{owned}->{$type});
  return $planet->{owned}->{$type};
}

sub call_callback {
  my $self = shift;
  my $cbname = shift;
  my @args = @_;
  if(defined $self->{callbacks}->{$cbname}) {
    my $cb = $self->{callbacks}->{$cbname};
    if(defined $cb->{method}) {
      my $meth = $cb->{method};
      #eval {
        $meth->($self,\@args,$cb->{args});
      #};
      #print "Callback $cbname Failed: $@" if($@);
    }
  }
}

sub set_callbacks {
  my $self = shift;
  my %params = @_;
  for my $k (keys %params) {
    $self->{callbacks}->{$k} = $params{$k};
  }
}

sub set_callback {
  my $self = shift;
  my $name = shift;
  my $method = shift;
  my @args = @_;

  $self->{callbacks}->{$name} = {
    method => $method,
    args   => \@args,
  };
}

1;


__END__

CREATE TABLE planets (
  id            int,
  x             int,
  y             int,
  row           int,
  col           int,
  owner         text,
  lastvisit     int,
  homeplanet    int,
  everowned     int,
  humanpings    int,
  industry      int,
  ships         int,
  is_feeding    int,
  owned         text
);

CREATE TABLE feeds (
  source        int,
  dest          int

);
CREATE TABLE enemies (
  module        text,
  dead          int,
  names         text,
  name          text,
  enemy_type    text,
  planet_count  int,
  type          text,
  home          int,

  homelost      int,
  next          int,
  stage         int,
  wait          int,
  search        text,
  ndiv          int
);
CREATE TABLE transports (
  source        int,
  dest          int,
  owner         text,
  ships         int,
  ping          int,
  timeleft      int
);

CREATE TABLE galacticempire (
  game_over     int,
  total_planets int,
  total_enemies int,
  current_year  int,
  human_home    int
);
