#!/usr/bin/perl

use strict;
use lib qw(/home/advanced/xjguy/perl);
use Storable;
use CGI qw(param);
use JSON;
use POSIX qw/strftime/;
use Fcntl ':flock';

my $scorefile = '';
if($ENV{HTTP_HOST} =~ /geweb/) {
  $scorefile = "/data/servers/geweb/scores.dat";
}
else {
  $scorefile = "/var/www/geweb/scores.dat";
}
my $lockfile = "$scorefile.lock";

my $ref = {
  data => [],
  error => 0,
  error_message => '',
  rank => 0,
};

if(param('command') eq "top10") {
  my $data = retrieve($scorefile);
  my @foo = sort { $a->{score} <=> $b->{score} } splice(@$data,0,10);
  my $rank = 1;
  for my $s (@foo) {
    $s->{rank} = $rank++;
  }
  $ref->{data} = \@foo;

  print "Content-type: application/json\n\n";
  print objToJson($ref);
}
elsif(param('command') eq "newscore") {
  my $data = retrieve($scorefile);
  
  
  open(LF,">$lockfile");
  flock(LF,LOCK_EX);

  my $date = strftime('%Y-%m-%d %H:%M:%S',localtime());
  my $name = param('name') || 'I forgot my name';
  my $score = param('score');
  my $map_key = param('map_key');

  push(@$data,{
    name => $name,
    date => $date,
    score => $score,
    map_key => $map_key,
  });

  @$data = sort { 
    $a->{score} <=> $b->{score} or $a->{date} cmp $b->{date} 
  } @$data;

  my $rank = 1;
  for my $s (@$data) {
    $s->{rank} = $rank++;
  }

  store($data,$scorefile);

  flock(LF,LOCK_UN);

  my $index = 0;
  for (my $i = 0; $i < @$data; $i++) {
    my $s = $data->[$i];
    if($s->{name} eq $name && $s->{date} eq $date && $s->{score} eq $score) {
      $index = $i;
      $ref->{rank} = $s->{rank};
    }
  }
  my $top = $index - 5;
  if($top < 0) {
    $top = 0;
  }
  my $bot = $top + 10;
  if($bot > $#$data) {
    $bot = $#$data;
  }
  my @set = ();
  for my $n ($top..$bot) {
    push(@set,$data->[$n]);
  }
  print "Content-type: application/json\n\n";
  $ref->{data} = \@set;
  print objToJson($ref);
}
