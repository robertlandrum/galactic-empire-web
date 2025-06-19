#!/usr/bin/perl
#

use strict;
use Gtk2;
use Gtk2::Pango;
my $planetinfo;

Gtk2->init;
my $window = Gtk2::Window->new('toplevel');
my $planetinfo_da = Gtk2::DrawingArea->new();
$planetinfo_da->size(
  80,
  180
);
$planetinfo_da->add_events([
  'exposure-mask',
]);

$planetinfo_da->signal_connect(
  'expose_event' => \&expose_handler,
);
$planetinfo_da->signal_connect(
  'configure_event' => \&configure_handler, 
);

my $scrollbar = Gtk2::VScrollbar->new(undef);
$scrollbar->set_increments(1,1000);
$scrollbar->set_range(0,10000);
$scrollbar->set_sensitive(1);
$scrollbar->signal_connect(
  'value-changed' => \&value_changed
);

my $do_battle = Gtk2::Button->new_with_label("Do Battle");
my $constant_feed = Gtk2::Button->new_with_label("Constant Feed");
my $launch_one = Gtk2::Button->new_with_label("Launch One");
my $launch_all = Gtk2::Button->new_with_label("Launch All");
my $launch = Gtk2::Button->new_with_label("Launch");
$do_battle->set_sensitive(1);
$launch->set_sensitive(0);
$launch_all->set_sensitive(0);
$constant_feed->set_sensitive(0);
$launch_one->set_sensitive(0);

my $table = Gtk2::Table->new(5,2,0);

$table->attach_defaults($do_battle,0,2,0,1);
$table->attach_defaults($constant_feed,0,2,1,2);
$table->attach_defaults($launch_one,0,2,2,3);
$table->attach_defaults($launch_all,0,2,3,4);
$table->attach_defaults($launch,0,2,4,5);
$table->attach_defaults($scrollbar,0,1,5,6);
$table->attach_defaults($planetinfo_da,1,2,5,6);


$window->signal_connect(
  destroy => sub { Gtk2->main_quit }
);
$window->add($table);
$window->show_all;
Gtk2->main;

sub planetinfo_configure_handler {
  my $widget = shift;
  my $event = shift;
  my $app = shift;
  $planetinfo = Gtk2::Gdk::Pixmap->new(
    $widget->window,
    $widget->allocation->width,
    $widget->allocation->height,
    -1
  );

  #my $map_color = Gtk2::Gdk::Color->new(221 * 257,221 * 257, 221 * 257);
  #my $map_color = Gtk2::Gdk::Color->parse('purple');

  #my $map_gc = Gtk2::Gdk::GC->new($widget->window);
  #$map_gc->set_rgb_bg_color($map_color);
  #$map_gc->set_rgb_fg_color($map_color);

  redraw_planetinfo($app);

  return 1;
}

sub show_from_data {
  my $app = shift;
  if(
    (!defined $app->{source} && !defined $app->{last_source}) ||
    (
      defined $app->{source} && 
      defined $app->{last_source} && 
      $app->{source}->{id} == $app->{last_source}->{id}
    )
  ) {
    # do nothing
    return;
  }
  elsif(!defined $app->{source} && defined $app->{last_source}) {
    # draw blank
    # ----------
    $app->{last_source} = undef;
    $planetinfo->draw_rectangle(
      $planetinfo_da->style->white_gc,
      1,
      0,
      0,
      $planetinfo_da->allocation->width,
      100
    );
    return;
  }
  elsif(defined $app->{source}) {
    # draw blank and draw source
    # draw a white rectangle
    # ----------------------
    $app->{last_source} = $app->{source};
    $planetinfo->draw_rectangle(
      $planetinfo_da->style->white_gc,
      1,
      0,
      0,
      $planetinfo_da->allocation->width,
      100
    );
  }
  my $p = $app->{source};

  my $worldname = "";
  my $icon = "";
  if($p->{owner} eq "INDEPENDENT") {
    $icon = "ind_icon_32x32.xpm";
    $worldname = "Indep. World";
  }
  elsif($p->{owner} eq "HUMAN") {
    $icon = "human_icon_32x32.xpm";
    $worldname = "Human World";
  }
  else {
    my $e = $app->{ge}->get_enemy($p->{owner});
    $icon = lc($e->{type})."_icon_32x32.xpm";
    $worldname = "$e->{name} World";
  }

  # Check to see if we can see this planets industry and ship total
  # ---------------------------------------------------------------
  my $industry = can_see_industry($app,$p) ? $p->{industry} : "?";
  my $ships = can_see_ships($app,$p) ? $p->{ships} : "?";


  # draw a white rectangle
  # ----------------------
  $planetinfo->draw_rectangle(
    $planetinfo_da->style->white_gc,
    1,
    0,
    0,
    $planetinfo_da->allocation->width,
    $planetinfo_da->allocation->height
  );

  $planetinfo->draw_layout(
    $planetinfo_da->style->black_gc,
    0,
    4,
    small_text_centered($planetinfo_da,$worldname)
  );

  $planetinfo->draw_pixbuf(
    $planetinfo_da->style->white_gc,
    get_pixbuf($icon),
    0,
    0,
    25,
    18,
    32,
    32,
    'none',
    undef,
    undef
  );
  $planetinfo->draw_layout(
    $planetinfo_da->style->black_gc,
    0,
    54,
    small_text_centered($planetinfo_da,"100 Ships")
  );
  $planetinfo->draw_layout(
    $planetinfo_da->style->black_gc,
    0,
    67,
    small_text_centered($planetinfo_da,"10 Industry")
  );

  # if there's no dest, and it's not ours, and 
  # not a home planet, show last visit
  # ------------------------------------------
  if(!defined $app->{dest} && $p->{owner} ne "HUMAN" && !$p->{homeplanet}) {
    # show last visited
    # -----------------
    my $last_visit = $p->{lastvisit} ? 
      ("Last Visited ".int($p->{lastvisit}/10).".".($p->{lastvisit} % 10)) :
      "Never Visited";

    $planetinfo->draw_layout(
      $planetinfo_da->style->black_gc,
      0,
      80,
      small_text_centered($planetinfo_da,$last_visit)
    );
  }

  return 1;
}


sub show_to_data {
  my $app = shift;

  if(
    (!defined $app->{dest} && !defined $app->{last_dest}) ||
    (
      defined $app->{dest} && 
      defined $app->{last_dest} && 
      $app->{dest}->{id} == $app->{last_dest}->{id}
    )
  ) {
    # do nothing
    return;
  }
  elsif(!defined $app->{dest} && defined $app->{last_dest}) {
    # draw blank
    # ----------
    $app->{last_dest} = undef;
    $planetinfo->draw_rectangle(
      $planetinfo_da->style->white_gc,
      1,
      0,
      100,
      $planetinfo_da->allocation->width,
      $planetinfo_da->allocation->height
    );
    return;
  }
  elsif(defined $app->{dest}) {
    # draw blank and draw dest
    # draw a white rectangle
    # ----------------------
    $app->{last_dest} = $app->{dest};
    $planetinfo->draw_rectangle(
      $planetinfo_da->style->white_gc,
      1,
      0,
      100,
      $planetinfo_da->allocation->width,
      $planetinfo_da->allocation->height
    );
  }

  my $p = $app->{dest};
  my $worldname = "";
  my $icon = "";
  if($p->{owner} eq "INDEPENDENT") {
    $icon = "ind_icon_32x32.xpm";
    $worldname = "Indep. World";
  }
  elsif($p->{owner} eq "HUMAN") {
    $icon = "human_icon_32x32.xpm";
    $worldname = "Human World";
  }
  else {
    my $e = $app->{ge}->get_enemy($p->{owner});
    $icon = lc($e->{type})."_icon_32x32.xpm";
    $worldname = "$e->{name} World";
  }

  # Check to see if we can see this planets industry and ship total
  # ---------------------------------------------------------------
  my $industry = can_see_industry($app,$p) ? $p->{industry} : "?";
  my $ships = can_see_ships($app,$p) ? $p->{ships} : "?";

  $planetinfo->draw_layout(
    $planetinfo_da->style->black_gc,
    0,
    100,
    small_text_centered($planetinfo_da,$worldname)
  );
  $planetinfo->draw_pixbuf(
    $planetinfo_da->style->white_gc,
    get_pixbuf($icon),
    0,
    0,
    25,
    114,
    32,
    32,
    'none',
    undef,
    undef
  );
  $planetinfo->draw_layout(
    $planetinfo_da->style->black_gc,
    0,
    149,
    small_text_centered($planetinfo_da,"$ships Ships")
  );
  $planetinfo->draw_layout(
    $planetinfo_da->style->black_gc,
    0,
    162,
    small_text_centered($planetinfo_da,"$industry Industry")
  );

  return 1; 
}

sub can_see_industry {
  my $app = shift;
  my $p = shift;

  # if it's ours, or a homeplanet, or we once owned it, or we've pinged it
  # more than twice, then we see industry.
  # ----------------------------------------------------------------------
  return (
    $p->{owner} eq "HUMAN" ||
    $p->{homeplanet} ||
    $app->{ge}->get_owned($p,"HUMAN") ||
    ($p->{humanpings} >= 3)
  );
}

sub can_see_ships {
  my $app = shift;
  my $p = shift;

  # if it's ours, or a homeplanet, or it's been a year or less since we last
  # visted the planet, or we once owned it, or we've pinged more than twice,
  # then we can see this planets ships.
  # ------------------------------------------------------------------------
  return (
    $p->{owner} eq "HUMAN" ||
    $p->{homeplanet} ||
    ($p->{lastvisit} && ($app->{ge}->{current_year} - $p->{lastvisit}) < 11) ||
    $app->{ge}->get_owned($p,"HUMAN") ||
    ($p->{humanpings} >= 3)
  );
}

sub get_pixbuf {
  my $name = shift;
  return $RESOURCES{$name} || load_pixbuf($name);
}

sub load_pixbuf {
  my $name = shift;
  my $pb = Gtk2::Gdk::Pixbuf->new_from_file("../xpms/$name");

  # Keep it around so we don't load it more than once
  # -------------------------------------------------
  $RESOURCES{$name} = $pb;
  return $pb;
}

sub small_text_centered {
  my $w = shift;
  my $text = shift;
  my $layout = $w->create_pango_layout($text);
  $layout->set_width(82 * PANGO_SCALE);
  $layout->set_wrap('word');
  $layout->set_alignment('center');
  $layout->set_markup("<small>$text</small>");
  $layout->set_font_description(
    Gtk2::Pango::FontDescription->from_string("sans 10")
  );
  return $layout;
}

sub planetinfo_expose_handler {
  my $widget = shift;
  my $event = shift;
  my $app = shift;

  redraw_planetinfo($app);

  return 0;
}

sub redraw_planetinfo {
  my $app = shift;

  # update the planetinfo pixmap
  # ----------------------------
  show_from_data($app);
  show_to_data($app);
  show_scrollbar($app);

  # Show the pixmap to the user by copying it to planetinfo drawing area
  # --------------------------------------------------------------------
  $planetinfo_da->window->draw_drawable(
    $planetinfo_da->style->fg_gc($planetinfo_da->state),
    $planetinfo,
    0,
    0,
    0,
    0,
    $planetinfo_da->allocation->width,
    $planetinfo_da->allocation->height
  );

  # this value isn't written into planetinfo pixbuf, so 
  # we don't have to worry about erasing it each time
  # ---------------------------------------------------
  if(defined $app->{scrollbar_value}) 
    my $value = $app->{scrollbar_value};
    $planetinfo_da->window->draw_layout(
      $planetinfo_da->style->black_gc,
      0,
      83,
      small_text_centered($planetinfo_da,"<b>$value Ships</b>");
    );
  }
}

sub show_scrollbar {
  my $app = shift;

  if(!$app->{scrollbar_inited}) {
    if(defined $app->{source} && $app->{source}->{owner} eq "HUMAN" &&
      $app->{source}->{ships} > 0) {
      my $ships = $app->{source}->{ships};
      my $inc = 1;
      if($ships > 10) { $inc = 10; }
      if($ships >= 200) { $inc = 20; }
      if($ships >= 300) { $inc = 30; }
      if($ships >= 400) { $inc = 40; }
      if($ships >= 500) { $inc = 50; }
      if($ships >= 1000) { $inc = 100; }
      if($ships >= 2000) { $inc = 200; }
      if($ships >= 3000) { $inc = 300; }
      if($ships >= 4000) { $inc = 400; }
      if($ships >= 5000) { $inc = 500; }

      $scrollbar->set_increments(1,$inc);
      $scrollbar->set_range(0,$ships);
      $scrollbar->set_sensitive(1);
      $app->{scrollbar_value} = 0;
    }
    else {
      $scrollbar->set_sensitive(0);
      $app->{scrollbar_value} = undef;
    }
    $app->{scrollbar_inited} = 1;
  }
}

sub scrollbar_value_changed {
  my $widget = shift;
  my $app = shift;

  my $value = int($widget->get_value);

  $app->{scrollbar_value} = $value;
  redraw_planetinfo($app);

  if($value > 0) {
    $launch->set_sensitive(1);
    $launch_all->set_sensitive(0);
    $launch_one->set_sensitive(0);
  }
  else {
    $launch->set_sensitive(0);
    $launch_all->set_sensitive(1);
    $launch_one->set_sensitive(1);
  }
}
