#!/usr/bin/perl

while(<*.xpm>) {
  my $p = $_;
  $p =~ s/\.xpm$/.png/;
  print "convert $_ pngs/$p\n";
}
