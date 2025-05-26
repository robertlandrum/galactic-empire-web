#!/usr/bin/perl

use strict;
use lib qw(/home/advanced/xjguy/perl);
use Storable;
use Date::Manip;
$|=1;
my $scorefile = "/var/www/geweb/scores.dat";
my $lockfile = "$scorefile.lock";

my ($name,$date,$score);

prompt('Name: ',\$name);
prompt('Date: ',\$date);
prompt('Score: ',\$score);
$date = UnixDate(ParseDate($date),"%Y-%m-%d %H:%M:%S");

my $data = [];
if(-e $scorefile) {
  $data = retrieve($scorefile);
}
push(@$data,{
  name => $name,
  date => $date,
  score => $score,
  map_key => "",
});

@$data = sort { 
  $a->{score} <=> $b->{score} or $a->{date} cmp $b->{date} 
} @$data;

my $rank = 1;
for my $s (@$data) {
  $s->{rank} = $rank++;
}
store($data,$scorefile);

sub prompt {
  my $text = shift;
  my $var = shift;
  print $text;
  my $data = <STDIN>;
  chomp($data);
  $$var = $data;
}
