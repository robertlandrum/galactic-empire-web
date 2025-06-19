#!/usr/bin/perl

use strict;
use Gnome2;
use Gtk2;

my $appname = "FileDialogTest";
my $appversion = "1.0";

Gnome2::Program->init ($appname, $appversion);
my $app = Gnome2::App->new ($appname);

my $h = 1;
my $w = Gtk2::FileChooserDialog->new("Save Game File",$app,'open');

$w->add_button('gtk-cancel','cancel');
$w->add_button('gtk-open','ok');
my $r = $w->run;
if($r eq "ok") {
  my $file = $w->get_filename;
  print "Got filename: $file\n";
}
$w->destroy;
#Gtk2->main;


__END__;

my $cancel = Gtk2::Button->new_from_stock('gtk-cancel');
$cancel->signal_connect(
  'released' => sub { Gtk2->main_quit },
);
$w->add_button($cancel);

my $open = Gtk2::Button->new_from_stock('gtk-open');
$open->signal_connect(
  'released' => sub { print "File: ".$w->get_filename."\n"; Gtk2->main_quit },
);
$w->add_button($open);

#$w->vbox->add($bb);
#$w->signal_connect(
  #'file-activated' => sub { print "File: ".$w->get_filename."\n"; }
#);
#$window->add($w);

$w->show_all;




Gtk2->main;

