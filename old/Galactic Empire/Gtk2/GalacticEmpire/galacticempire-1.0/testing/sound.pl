#!/usr/bin/perl

use strict;
use Gnome2;

my $snd = Gnome2::Sound->init("localhost");

opendir(DIR,"/home/rlandrum/GalacticEmpire/sounds");
my @f = readdir(DIR);
closedir(DIR);

for my $file (@f) {
  next unless($file =~ /\.wav$/);
  next unless($file =~ /home/);
  print "Playing $file\n";
  Gnome2::Sound->play("/home/rlandrum/GalacticEmpire/sounds/$file");
  my $f = <STDIN>;

}

Gnome2::Sound->shutdown;
