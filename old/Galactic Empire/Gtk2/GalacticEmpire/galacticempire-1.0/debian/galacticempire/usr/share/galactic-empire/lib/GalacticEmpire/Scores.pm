package GalacticEmpire::Scores;

use strict;
use Data::Dumper;
use DBI;
use POSIX qw/strftime/;

sub new {
  my $class = shift;
  my $file = shift;
  my $self = {};
  bless($self,$class);
  $self->{scoredb} = $file;
  $self->initdb();
  return $self;
}


sub check_high_score {
  my $self = shift;
  my $score = shift;
  
  my @scores = $self->scores();

  # If there are less than 10 scores, then this is a high score
  # -----------------------------------------------------------
  if(@scores < 10) {
    return 1;
  }

  # We have 10 scores...
  # --------------------
  for my $s (@scores) {
    # See if our score is better (less is better)
    # -------------------------------------------
    if($s->{score} > $score) {
      return 1;
    }
  }
  return 0;
}

sub add_score {
  my $self = shift;
  my $score = shift;
  my $name  = shift;
  my $year  = shift;
  my $enemies = shift;
  my $enemycount = shift;
  my $now = strftime("%Y-%m-%d %H:%M:%S",localtime());

  my $dbh = $self->db_connect();
  $dbh->do("INSERT INTO scores (score,name,year,enemies,enemycount,gamedate) VALUES (?,?,?,?,?,?)",{},$score,$name,$year,$enemies,$enemycount,$now);

  my $id = $dbh->func('last_insert_rowid');

  # If we have more than 10 scores, delete the max score
  # ----------------------------------------------------
  my @scores = $self->scores();
  if(@scores > 10) {
    my $max = (sort { $b->{score} <=> $a->{score} or $a->{id} <=> $b->{id} } @scores)[0]->{id};
    $dbh->do("DELETE FROM scores WHERE id = ?",{},$max);
  }

  return $id;
}

sub clear_scores {
  my $self = shift;
  my $dbh = $self->db_connect();
  $dbh->do("DELETE FROM scores");
}

sub scores {
  my $self = shift;
  my $dbh = $self->db_connect();

  my $s = $dbh->selectall_arrayref("SELECT * FROM scores",{Slice => {}});

  return wantarray ? @$s : $s;
}

sub db_connect {
  my $self = shift;

  unless($self->{dbh}) {
    $self->{dbh} = DBI->connect("dbi:SQLite:dbname=$self->{scoredb}");
  }
  return $self->{dbh};
}

sub DESTROY {
  my $self = shift;
  if($self->{dbh}) {
    $self->{dbh}->disconnect;
  }
}

sub initdb {
  my $self = shift;
  my $dbh = $self->db_connect;
  
  my @t = $dbh->tables;
  unless(grep(/scores/,@t)) {
    my $c = qq[
      CREATE TABLE scores (
        id       INTEGER PRIMARY KEY,
        score    REAL,
        name     TEXT,
        year     INT,
        enemies  TEXT,
        enemycount INT,
        gamedate TEXT
      )
    ];
    $dbh->do($c);
  }
}

1;
