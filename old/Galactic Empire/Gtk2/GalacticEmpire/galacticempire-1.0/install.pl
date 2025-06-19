#!perl

use File::Copy;
use File::Basename;
use File::Path;
use Getopt::Long;

my %options = ();
GetOptions(\%options,
  'PREFIX=s',
  'BASE=s',   # /usr (maybe)
);

my $PREFIX = $options{PREFIX} || $ENV{PREFIX};
my $BASE = $options{BASE} || $ENV{BASE};

die "No BASE" unless($BASE);

my @install = `find`;
chomp(@install);
my %lookup = map { (basename($_)) => $_ } @install;
my @list = qw(
  bin/galactic-empire.pl
  share/pixmaps/ge_icon_32x32.xpm
  share/menu/galacticempire
  share/applications/galacticempire.desktop
  share/application-registry/galacticempire.applications
  share/galactic-empire/lib/GalacticEmpire
  share/galactic-empire/lib/GalacticEmpire.pm
  share/galactic-empire/lib/GalacticEmpire/Enemy
  share/galactic-empire/lib/GalacticEmpire/Enemy.pm
  share/galactic-empire/lib/GalacticEmpire/Scores.pm
  share/galactic-empire/lib/GalacticEmpire/Enemy/Arachs.pm
  share/galactic-empire/lib/GalacticEmpire/Enemy/Blobs.pm
  share/galactic-empire/lib/GalacticEmpire/Enemy/Bots.pm
  share/galactic-empire/lib/GalacticEmpire/Enemy/Bozos.pm
  share/galactic-empire/lib/GalacticEmpire/Enemy/Czins.pm
  share/galactic-empire/lib/GalacticEmpire/Enemy/Gubrus.pm
  share/galactic-empire/lib/GalacticEmpire/Enemy/Mutants.pm
  share/galactic-empire/lib/GalacticEmpire/Enemy/Nukes.pm
  share/galactic-empire/xpms
  share/galactic-empire/xpms/about_ge.xpm
  share/galactic-empire/xpms/arachs_headstone.xpm
  share/galactic-empire/xpms/arachs_icon_32x32.xpm
  share/galactic-empire/xpms/arachs_planet.xpm
  share/galactic-empire/xpms/big_bottom_left.xpm
  share/galactic-empire/xpms/big_bottom_right.xpm
  share/galactic-empire/xpms/big_top_left.xpm
  share/galactic-empire/xpms/big_top_right.xpm
  share/galactic-empire/xpms/blobs_headstone.xpm
  share/galactic-empire/xpms/blobs_icon_32x32.xpm
  share/galactic-empire/xpms/blobs_planet.xpm
  share/galactic-empire/xpms/bots_headstone.xpm
  share/galactic-empire/xpms/bots_icon_32x32.xpm
  share/galactic-empire/xpms/bots_planet.xpm
  share/galactic-empire/xpms/bozos_headstone.xpm
  share/galactic-empire/xpms/bozos_icon_32x32.xpm
  share/galactic-empire/xpms/bozos_planet.xpm
  share/galactic-empire/xpms/czin_headstone.xpm
  share/galactic-empire/xpms/czin_icon_32x32.xpm
  share/galactic-empire/xpms/czin_planet.xpm
  share/galactic-empire/xpms/ge_icon_32x32.xpm
  share/galactic-empire/xpms/gubru_headstone.xpm
  share/galactic-empire/xpms/gubru_icon_32x32.xpm
  share/galactic-empire/xpms/gubru_planet.xpm
  share/galactic-empire/xpms/hall_of_fame.xpm
  share/galactic-empire/xpms/human_feed_planet.xpm
  share/galactic-empire/xpms/human_icon_32x32.xpm
  share/galactic-empire/xpms/human_planet.xpm
  share/galactic-empire/xpms/human_zero_planet.xpm
  share/galactic-empire/xpms/independent_icon_32x32.xpm
  share/galactic-empire/xpms/independent_planet.xpm
  share/galactic-empire/xpms/mutants_headstone.xpm
  share/galactic-empire/xpms/mutants_icon_32x32.xpm
  share/galactic-empire/xpms/mutants_planet.xpm
  share/galactic-empire/xpms/nukes_headstone.xpm
  share/galactic-empire/xpms/nukes_icon_32x32.xpm
  share/galactic-empire/xpms/nukes_planet.xpm
  share/galactic-empire/xpms/small_bottom_left.xpm
  share/galactic-empire/xpms/small_bottom_right.xpm
  share/galactic-empire/xpms/small_top_left.xpm
  share/galactic-empire/xpms/small_top_right.xpm
  share/galactic-empire/sounds
  share/galactic-empire/sounds/103losehome.wav
  share/galactic-empire/sounds/116capturehome.wav
  share/galactic-empire/sounds/131winnorecord.wav
  share/galactic-empire/sounds/142launchone.wav
  share/galactic-empire/sounds/143constantfeed.wav
  share/galactic-empire/sounds/513endofgame.wav
  share/galactic-empire/sounds/516homehit.wav
  share/galactic-empire/sounds/517valkyries.wav
  share/galactic-empire/sounds/520bummer.wav
  share/galactic-empire/sounds/525launch.wav
  share/galactic-empire/sounds/555attackfail.wav
  share/galactic-empire/sounds/601victorygood.wav
  share/galactic-empire/sounds/601victory.wav
  share/galactic-empire/sounds/658nukestakehome.wav
  share/galactic-empire/sounds/659bozostakehome.wav
);


for my $tgt (@list) {
  my $src = find_file($tgt);
  if($src) {
    my $target = "$PREFIX/$BASE/$tgt";
    #my ($target_dir) = dirbase($target);
    my $target_dir = dirname($target);

    if(-d $src) {
      mkpath($target,0,0755);
    }
    else {
      unless(-d $target_dir) {
        mkpath($target_dir,0,0755);
      }
      copy($src,$target);
      if($target =~ /bin/) {
        chmod(0755,$target);
      }
      else {
        chmod(0644,$target);
      }
    }
  }
  else {
    print "Unable to located source for $tgt\n";
  }
}


open(FILE,">$PREFIX/$BASE/bin/galactic-empire");
print FILE "#!/bin/sh\n";
print FILE "export GE_SHARE=$BASE/share/galactic-empire\n";
print FILE "export PERLLIB=$BASE/share/galactic-empire/lib\n";
print FILE "$BASE/bin/galactic-empire.pl\n";
close(FILE);
chmod(0755,"$PREFIX/$BASE/bin/galactic-empire");

init_scores();

sub find_file {
  my $path = shift;
  my $bn = basename($path);
  return $lookup{$bn};
}

sub find_perms {
  my $target = shift;
  if($target =~ /bin\//) {
    return 0755;
  }
  elsif($target =~ /share\//) {
    return 0711;
  }
  return 0700;
}
    

sub dirbase {
  my $target = shift;
  if($target =~ /^(.+)\/([^\/]+)$/) {
    return ($1,$2);
  }
  return;
}

sub init_scores {
  mkdir("$PREFIX/$BASE/share/galactic-empire/scores",0777);
  my $f = "$PREFIX/$BASE/share/galactic-empire/scores/scores.sf";
  eval q[
    use lib qw(./lib);
    use GalacticEmpire::Scores;
    my $m = GalacticEmpire::Scores->new($f);
    chmod(0666,$f);
  ];
}
