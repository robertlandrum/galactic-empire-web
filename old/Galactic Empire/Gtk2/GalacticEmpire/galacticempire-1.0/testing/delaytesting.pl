use Time::HiRes qw(usleep);
$|=1;
my $text = "The Defenders Held";

print $text;
game_delay(75);
print chr(8) x length($text);
print "Bar";
print " " x length($text);
print "\n";

sub game_delay {
  my $n = shift;
  my $d = $n * 10000;
  usleep($d);
}

my $fb = 10000;
my $sb = 25000;
my $rsb = 50000;
my $rfb = 5000;
my $lfb = 1000;

Lightning Fast Battles
Really Fast Battles
Fast Battles
Slow Battles
Really Slow Battles
