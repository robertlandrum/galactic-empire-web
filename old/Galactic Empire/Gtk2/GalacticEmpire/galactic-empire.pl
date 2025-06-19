#!/usr/bin/perl
#

use Data::Dumper;
use strict;
#use lib qw(/usr/share/galactic-empire/lib);
use lib qw(./lib);
use Gtk2;
use Gtk2::Pango;
use Gnome2;
use Time::HiRes qw(usleep);
use GalacticEmpire;
use GalacticEmpire::Scores;
use constant PLANETROWS => 27;
use constant PLANETCOLS => 32;
use constant PLANETWIDTH => 16;
use constant PLANETHEIGHT => 16;
#my $AUTOBATTLE = 0;
my $XPM_PATH = "$ENV{GE_SHARE}/xpms";
my $SND_PATH = "$ENV{GE_SHARE}/sounds";
my $SCOREFILE = "$ENV{GE_SHARE}/scores/scores.sf";
my %RESOURCES = ();
my $ge = GalacticEmpire->new();
#my $SPEED = $AUTOBATTLE ? 1000 : 5000;


my $app = {
  source => undef,
  dest => undef,
  last_dest => undef,
  last_source => undef,
  scrollbar_value => undef,
  scrollbar_inited => 0,
  button_pressed   => 0,
  menu_dead_list   => [],
  menus            => [],
  battling         => 0,
  bubble_transport => undef,
  prefs => {
    sound => 1,
    autobattle => 0,
    speed => 5000,
  },
  ge => $ge,
};


$ge->set_callback('current_year',\&show_current_year,$app);
$ge->set_callback('fortify',\&show_fortify,$app);
$ge->set_callback('delay',\&do_delay,$app);
$ge->set_callback('game_won',\&show_game_won,$app);
$ge->set_callback('game_lost',\&show_game_lost,$app);
$ge->set_callback('attack_setup',\&show_attack_setup,$app);
$ge->set_callback('attack_update',\&show_attack_update,$app);
$ge->set_callback('attackers_win',\&show_attack_win,$app);
$ge->set_callback('defenders_win',\&show_attack_hold,$app);
$ge->set_callback('enemy_dead',\&show_enemy_dead,$app);

my $planetmap;
my $planetinfo;



Gnome2::Sound->init("localhost");
Gtk2->init;

# Preload Pixbufs
# ---------------
for my $pb (qw(
  about_ge.xpm
  arachs_headstone.xpm
  arachs_icon_32x32.xpm
  arachs_planet.xpm
  big_bottom_left.xpm
  big_bottom_right.xpm
  big_top_left.xpm
  big_top_right.xpm
  blobs_headstone.xpm
  blobs_icon_32x32.xpm
  blobs_planet.xpm
  bots_headstone.xpm
  bots_icon_32x32.xpm
  bots_planet.xpm
  bozos_headstone.xpm
  bozos_icon_32x32.xpm
  bozos_planet.xpm
  czin_headstone.xpm
  czin_icon_32x32.xpm
  czin_planet.xpm
  ge_icon_32x32.xpm
  gubru_headstone.xpm
  gubru_icon_32x32.xpm
  gubru_planet.xpm
  hall_of_fame.xpm
  human_feed_planet.xpm
  human_icon_32x32.xpm
  human_planet.xpm
  human_zero_planet.xpm
  independent_icon_32x32.xpm
  independent_planet.xpm
  mutants_headstone.xpm
  mutants_icon_32x32.xpm
  mutants_planet.xpm
  nukes_headstone.xpm
  nukes_icon_32x32.xpm
  nukes_planet.xpm
  small_bottom_left.xpm
  small_bottom_right.xpm
  small_top_left.xpm
  small_top_right.xpm
)) {
  load_pixbuf($pb);

}

# Define the new Main Window
# --------------------------
my $window = Gtk2::Window->new('toplevel');
$window->set_title("Galactic Empire");

# Define the drawing area for the planetmap
# -----------------------------------------
my $planetmap_da = Gtk2::DrawingArea->new();
$planetmap_da->size(
  PLANETCOLS*PLANETWIDTH,
  PLANETROWS*PLANETHEIGHT
);

init_planetmap_signals($app);

sub init_planetmap_signals {
  my $app = shift;
  $planetmap_da->add_events([
    'exposure-mask',
    'pointer-motion-mask',
    'pointer-motion-hint-mask',
    'button-press-mask',
    'button-release-mask'
  ]);
  $planetmap_da->signal_connect(
    'expose_event' => \&planetmap_expose_handler, $app
  );
  $planetmap_da->signal_connect(
    'motion_notify_event' => \&planetmap_motion_handler, $app
  );
  $planetmap_da->signal_connect(
    'configure_event' => \&planetmap_configure_handler, $app
  );
  $planetmap_da->signal_connect(
    'button_press_event' => \&planetmap_button_handler, $app
  );
  $planetmap_da->signal_connect(
    'button_release_event' => \&planetmap_button_handler, $app
  );
}

# Define the drawing area for the time and distance info
# ------------------------------------------------------
my $timedistance_da = Gtk2::DrawingArea->new();
$timedistance_da->size(
  100,
  100
);
init_timedistance_signals($app);

sub init_timedistance_signals {
  my $app = shift;
  $timedistance_da->add_events([
    'exposure-mask',
  ]);

  $timedistance_da->signal_connect(
    'expose_event' => \&timedistance_expose_handler, $app
  );
  $timedistance_da->signal_connect(
    'configure_event' => \&timedistance_configure_handler,  $app
  );
}

# Define the drawing area for the planet info
# -------------------------------------------
my $planetinfo_da = Gtk2::DrawingArea->new();
$planetinfo_da->size(
  80,
  180
);
init_planetinfo_signals($app);
sub init_planetinfo_signals {
  my $app = shift;
  $planetinfo_da->add_events([
    'exposure-mask',
  ]);

  $planetinfo_da->signal_connect(
    'expose_event' => \&planetinfo_expose_handler, $app
  );
  $planetinfo_da->signal_connect(
    'configure_event' => \&planetinfo_configure_handler,  $app
  );
}

# Define the scrollbar for setting ship launch amounts
# ----------------------------------------------------
my $scrollbar = Gtk2::VScrollbar->new(undef);
#$scrollbar->set_increments(1,1000);
#$scrollbar->set_range(0,10000);
$scrollbar->set_sensitive(0);
init_scrollbar_signals($app);

sub init_scrollbar_signals {
  my $app = shift;
  $scrollbar->signal_connect(
    'value-changed' => \&scrollbar_value_changed, $app
  );
}

# Define the buttons for launching/battling
# -----------------------------------------
my $do_battle = Gtk2::Button->new_with_label("Do Battle");
my $constant_feed = Gtk2::Button->new_with_label("Constant Feed");
my $ping = Gtk2::Button->new_with_label("Ping");
my $scan = Gtk2::Button->new_with_label("Scan");
my $launch_all = Gtk2::Button->new_with_label("Launch All");
my $launch = Gtk2::Button->new_with_label("Launch");
$do_battle->set_sensitive(1);
$launch->set_sensitive(0);
$launch_all->set_sensitive(0);
$constant_feed->set_sensitive(0);
$ping->set_sensitive(0);
$scan->set_sensitive(0);

init_button_signals($app);

sub init_button_signals {
  my $app = shift;
  $do_battle->signal_connect(
    'clicked' => \&handle_battle,  $app
  );
  $constant_feed->signal_connect(
    'clicked' => \&handle_constant_feed,  $app
  );
  $ping->signal_connect(
    'clicked' => \&handle_launch_one,  $app
  );
  $scan->signal_connect(
    'clicked' => \&handle_scan,  $app
  );
  $launch_all->signal_connect(
    'clicked' => \&handle_launch_all,  $app
  );
  $launch->signal_connect(
    'clicked' => \&handle_launch,  $app
  );
}


# Define the table to hold all these items
# ----------------------------------------
my $table = Gtk2::Table->new(6,3,0);

$table->attach_defaults($planetmap_da,0,1,0,7);
$table->attach_defaults($timedistance_da,1,3,0,1);
$table->attach_defaults($do_battle,1,3,1,2);
$table->attach_defaults($constant_feed,1,3,2,3);

my $pingscanbox = Gtk2::HBox->new(0,0);
$pingscanbox->add($ping);
$pingscanbox->add($scan);
$table->attach_defaults($pingscanbox,1,3,3,4);

$table->attach_defaults($launch_all,1,3,4,5);
$table->attach_defaults($launch,1,3,5,6);
$table->attach_defaults($scrollbar,1,2,6,7);
$table->attach_defaults($planetinfo_da,2,3,6,7);

# Create a Vertical Box to hold our menubar and table
# ---------------------------------------------------
my $main_vbox = new Gtk2::VBox( 0, 1 );
$main_vbox->set_border_width( 1 );

# Create the menubar
# ------------------
my $menubar = create_menu_bar( $window );
$main_vbox->pack_start( $menubar, 0, 1, 0 );
$main_vbox->pack_start( $table, 0, 1, 0 );

$window->signal_connect(
  destroy => sub { Gtk2->main_quit }
);
$window->add( $main_vbox );
$window->show_all;


Gtk2->main;

sub planetmap_configure_handler {
  my $widget = shift;
  my $event = shift;
  my $app = shift;

  # Create the blank pixmap
  # -----------------------
  $planetmap = Gtk2::Gdk::Pixmap->new(
    $widget->window,
    $widget->allocation->width,
    $widget->allocation->height,
    -1
  );

  update_planetmap($app);
  redraw_planetmap();
}

sub update_planetmap {
  my $app = shift;

  my $map_color = Gtk2::Gdk::Color->new(221 * 257,221 * 257, 221 * 257);

  my $map_gc = Gtk2::Gdk::GC->new($planetmap_da->window);
  $map_gc->set_rgb_bg_color($map_color);
  $map_gc->set_rgb_fg_color($map_color);
  $planetmap->draw_rectangle(
    $map_gc,
    1,
    0,
    0,
    $planetmap_da->allocation->width,
    $planetmap_da->allocation->height
  );

  for my $i (0..$#{$app->{ge}->{planets}}) {
    my $p = $app->{ge}->{planets}->[$i];
    update_planet($p,$map_gc);
  }
  return 1; 
}

sub update_planet {
  my $p = shift;
  my $map_gc = shift;

  unless($map_gc) {
    my $map_color = Gtk2::Gdk::Color->new(221 * 257,221 * 257, 221 * 257);

    $map_gc = Gtk2::Gdk::GC->new($planetmap_da->window);
    $map_gc->set_rgb_bg_color($map_color);
    $map_gc->set_rgb_fg_color($map_color);
  }

  if($p->{owner} ne "NOPLANET") {
    my $planeticon;
    if($p->{owner} ne "HUMAN") {
      $planeticon = lc($p->{owner})."_planet.xpm";
    }
    else {
      if($p->{is_feeding}) {
        # use feeding icon
        $planeticon = "human_feed_planet.xpm";
      }
      elsif($p->{industry} == 0) {
        # use zero
        $planeticon = "human_zero_planet.xpm";
      }
      else {
        # use normal
        $planeticon = "human_planet.xpm";
      }
    }
    # Wipe out any existing planet
    # ----------------------------
    $planetmap->draw_rectangle(
      $map_gc,
      1,
      $p->{x},
      $p->{y},
      PLANETWIDTH,
      PLANETHEIGHT
    );
    $planetmap->draw_pixbuf(
      $map_gc,
      get_pixbuf($planeticon),
      0,
      0,
      $p->{x},
      $p->{y},
      PLANETWIDTH,
      PLANETHEIGHT,
      'none',
      undef,
      undef
    );
  }
}

sub redraw_planetmap {
  # copy the stored planetmap pixmap into the drawing area
  # ------------------------------------------------------
  $planetmap_da->window->draw_drawable(
    $planetmap_da->style->fg_gc($planetmap_da->state),
    $planetmap,
    0,
    0,
    0,
    0,
    $planetmap_da->allocation->width,
    $planetmap_da->allocation->height
  );

  if($app->{bubble_transport}) {
    # bubble on
    show_attack_bubble($app->{bubble_transport});
  }

  gui_wait();
}

sub planetmap_expose_handler {
  my $widget = shift;
  my $event = shift;
  my $app = shift;

  redraw_planetmap();
  if($app->{source}) {
    draw_planet_select($widget,$app->{source});
    if($app->{dest}) {
      draw_planet_select($widget,$app->{dest});
    }
  }
  if($app->{source} && $app->{dest}) {
    draw_planet_line($widget,$app->{source},$app->{dest});
  }
  return 0;
}

sub draw_planet_select {
  my $widget = shift;
  my $planet = shift;
  $widget->window->draw_rectangle(
    $widget->style->black_gc,
    0,
    $planet->{x},
    $planet->{y},
    PLANETWIDTH-1,
    PLANETHEIGHT-1
  );
}
sub draw_planet_line {
  my $widget = shift;
  my $src = shift;
  my $dest = shift;

  $widget->window->draw_line(
    $widget->style->black_gc,
    $src->{x}+8,
    $src->{y}+8,
    $dest->{x}+8,
    $dest->{y}+8
  );
}

sub draw_planet_fortify {
  my $widget = shift;
  my $transport = shift;
  my $text = $transport->{ships} == 1 ? 
    "1 ship fortifies" : 
    "$transport->{ships} ships fortify";

  my $bubble = draw_planet_bubble($widget,$transport->{dest},'small');
  draw_bubble_text($widget,$bubble,$text);
  gui_wait();
}

sub draw_bubble_text {
  my $widget = shift;
  my $bubble = shift;
  my $text = shift;

  my $layout = $widget->create_pango_layout($text);
  $layout->set_width($bubble->{width} * PANGO_SCALE);
  $layout->set_wrap('word');
  $layout->set_alignment('left');
  $layout->set_markup("<small>$text</small>");
  $layout->set_font_description(
    Gtk2::Pango::FontDescription->from_string("sans 10")
  );
  $widget->window->draw_layout(
    $widget->style->black_gc,
    $bubble->{text_pos_x},
    $bubble->{text_pos_y},
    $layout
  );

}
sub draw_planet_bubble {
  my $widget = shift;
  my $planet = shift;
  my $size = shift;
  my $tb = "bottom";
  my $lr = "left";

  my $bubblename = "${size}_${tb}_${lr}.xpm";
  my $bubble = {};
  my $pixbuf = get_pixbuf($bubblename);

  my $height = $pixbuf->get_height();
  my $width = $pixbuf->get_width();

  $bubble->{width} = $width;
  $bubble->{height} = $height;

  my $bound_width = $widget->allocation->width;
  my $bound_height = $widget->allocation->height;

  my $pos_x = $planet->{x}+8;
  my $pos_y = ($planet->{y}-$height)+8;

  $bubble->{text_pos_x} = $pos_x+8;
  $bubble->{text_pos_y} = $pos_y+7;

  if( (($planet->{y}-$height)+8) < 0 ) {
    # gotta be top
    $tb = "top";
    $pos_y = $planet->{y}+8;
    $bubble->{text_pos_y} = $pos_y+23;
  }
  if( ($planet->{x}+8+$width) > $bound_width ) {
    # gotta be right
    $lr = "right";
    $pos_x = ($planet->{x}-$width)+8;
    $bubble->{text_pos_x} = $pos_x+8;
  }
  $bubblename = "${size}_${tb}_${lr}.xpm";
  
  $pixbuf = get_pixbuf($bubblename);
  $bubble->{pos_x} = $pos_x;
  $bubble->{pos_y} = $pos_y;
  $bubble->{lr} = $lr;
  $bubble->{tb} = $tb;


  $widget->window->draw_pixbuf(
    $widget->style->black_gc,
    $pixbuf,
    0,
    0,
    $pos_x,
    $pos_y,
    $width,
    $height,
    'none',
    undef,
    undef
  );


  return $bubble;

}

sub planetmap_button_handler {
  my $widget = shift;
  my $event = shift;
  my $app = shift;
  return if($app->{battling});

  my $x = $event->type;
  if($event->button == 1) {
    $app->{scrollbar_inited} = 0;
    my ($wap,$x,$y,$mask) = $event->window->get_pointer();
    if($event->type eq 'button-press') {
      redraw_planetmap();
      $app->{source} = undef;
      $app->{dest} = undef;

      my $planet = get_planet($x,$y,$app);
      
      if($planet) {
        $app->{button_pressed} = 1;
        $app->{source} = $planet;

        # Turn off feeding if it's on
        # ---------------------------
        if($planet->{is_feeding}) {
          $planet->{is_feeding} = 0;
          $app->{ge}->remove_feed($planet);
          update_planetmap($app);
          redraw_planetmap($app);
        }

        # Draw a square around the planet
        # -------------------------------
        draw_planet_select($widget,$planet);
      }
      else {
        $app->{button_pressed} = 0;
      }
    }
    elsif($event->type eq 'button-release') {
      redraw_planetmap();
      my $planet = get_planet($x,$y,$app);
      $app->{button_pressed} = 0;
      if(defined $planet && defined $app->{source} && $app->{source}{id} != $planet->{id}) {
        $app->{dest} = $planet;
        draw_planet_select($widget,$app->{source});
        draw_planet_select($widget,$app->{dest});
        draw_planet_line($widget,$app->{source},$app->{dest});
      }
      elsif(defined $app->{source}) {
        draw_planet_select($widget,$app->{source});
      }
    }
    # update the planetinfo and buttons
    # ---------------------------------
    redraw_scrollbar($app);
    redraw_planetinfo($app);
    redraw_buttons($app);
    redraw_timedistance($app);

  }

  return 1;
}

sub get_planet {
  my $x = shift;
  my $y = shift;
  my $app = shift;
  my $row = int($y / PLANETHEIGHT);
  my $col = int($x / PLANETWIDTH);
  my $p = $app->{ge}->{planets}[($row * PLANETCOLS) + $col];
  if(defined $p && $p->{owner} eq "NOPLANET") {
    return undef;
  }
  return $p;
}

sub planetmap_motion_handler {
  my $widget = shift;
  my $event = shift;
  my $app = shift;

  if($app->{button_pressed} && defined $app->{source}) {
    redraw_planetmap();
    draw_planet_select($widget,$app->{source});

    my ($wap,$x,$y,$mask);
    if($event->is_hint) {
      ($wap,$x,$y,$mask) = $event->window->get_pointer();
    }
    else {
      $x = $event->x;
      $y = $event->y;
    }
    $widget->window->draw_line(
      $widget->style->black_gc,
      $app->{source}->{x}+8,
      $app->{source}->{y}+8,
      $x,
      $y
    );
  }

  return 1;
}

sub redraw_timedistance {
  my $app = shift;

  my $color = hex_to_color("999999");
  my $td_gc = Gtk2::Gdk::GC->new($timedistance_da->window);
  $td_gc->set_rgb_bg_color($color);
  $td_gc->set_rgb_fg_color($color);

  # make sure it's blank
  # --------------------
  $timedistance_da->window->draw_rectangle(
    $td_gc,
    1,
    0,
    0,
    $timedistance_da->allocation->width,
    $timedistance_da->allocation->height
  );

  my $c = $app->{ge}->{current_year};
  my $current_year = $c ? int($c/10).".".($c%10) : "0.0";

  my $travel_time = "";
  if(defined $app->{source} && defined $app->{dest}) {
    my $t = $ge->calculate_travel_time($app->{source},$app->{dest});
    $travel_time = int($t/10).".".($t%10) if($t);
  }
  
  my $x = 10;
  my $tt = $timedistance_da->create_pango_layout("Travel Time");
  $tt->set_width(100 * PANGO_SCALE);
  $tt->set_wrap('word');
  $tt->set_alignment('center');
  $tt->set_markup("<small><b>Travel Time</b></small>");
  $tt->set_font_description(
    Gtk2::Pango::FontDescription->from_string("sans 10")
  );
  $timedistance_da->window->draw_layout(
    $timedistance_da->style->black_gc,
    0,
    $x,
    $tt,
  );
  $x += 15;
  if($travel_time) {
    my $ttval = $timedistance_da->create_pango_layout("Travel Time");
    $ttval->set_width(100 * PANGO_SCALE);
    $ttval->set_wrap('word');
    $ttval->set_alignment('center');
    $ttval->set_markup("<small><b>$travel_time</b></small>");
    $ttval->set_font_description(
      Gtk2::Pango::FontDescription->from_string("sans 10")
    );
    $timedistance_da->window->draw_layout(
      $timedistance_da->style->black_gc,
      0,
      $x,
      $ttval,
    );
  }
  $x += 25;

  my $year = $timedistance_da->create_pango_layout("Year");
  $year->set_width(100 * PANGO_SCALE);
  $year->set_wrap('word');
  $year->set_alignment('center');
  $year->set_markup("<small><b>Year</b></small>");
  $year->set_font_description(
    Gtk2::Pango::FontDescription->from_string("sans 10")
  );

  $timedistance_da->window->draw_layout(
    $timedistance_da->style->black_gc,
    0,
    $x,
    $year,
  );
  $x += 15;


  my $yearval = $timedistance_da->create_pango_layout("Year");
  $yearval->set_width(100 * PANGO_SCALE);
  $yearval->set_wrap('word');
  $yearval->set_alignment('center');
  $yearval->set_markup("<small><b>$current_year</b></small>");
  $yearval->set_font_description(
    Gtk2::Pango::FontDescription->from_string("sans 10")
  );
  $timedistance_da->window->draw_layout(
    $timedistance_da->style->black_gc,
    0,
    $x,
    $yearval,
  );
}

sub timedistance_configure_handler {
  my $widget = shift;
  my $event = shift;
  my $app = shift;


  redraw_timedistance($app);

  return 1;
}

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

  # make sure it's blank
  # --------------------
  $planetinfo->draw_rectangle(
    $planetinfo_da->style->white_gc,
    1,
    0,
    0,
    $planetinfo_da->allocation->width,
    $planetinfo_da->allocation->height
  );

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
    $icon = "independent_icon_32x32.xpm";
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
    small_text_centered($planetinfo_da,"$ships Ships")
  );
  $planetinfo->draw_layout(
    $planetinfo_da->style->black_gc,
    0,
    67,
    small_text_centered($planetinfo_da,"$industry Industry")
  );

  # if there's no dest, and it's not ours, and 
  # not a home planet, show last visit
  # ------------------------------------------
  if(!defined $app->{dest} && $p->{owner} ne "HUMAN" && !$p->{homeplanet}) {
    # show last visited
    # -----------------
    my $last_visit = $p->{lastvisit} ? 
      ("Last Visit ".int($p->{lastvisit}/10).".".($p->{lastvisit} % 10)) :
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
    $icon = "independent_icon_32x32.xpm";
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

sub play_sound {
  my $sound = shift;
  $sound .= ".wav" unless($sound =~ /\.wav$/);
  if($app->{prefs}->{sound}) {
    Gnome2::Sound->play("$SND_PATH/$sound");
  }
}

sub load_pixbuf {
  my $name = shift;
  my $pb = Gtk2::Gdk::Pixbuf->new_from_file("$XPM_PATH/$name");

  # Keep it around so we don't load it more than once
  # -------------------------------------------------
  $RESOURCES{$name} = $pb;
  return $pb;
}

sub small_text_centered {
  my $w = shift;
  my $text = shift;
  my $width = shift || 82;
  my $layout = $w->create_pango_layout($text);
  $layout->set_width($width * PANGO_SCALE);
  $layout->set_wrap('word');
  $layout->set_alignment('center');
  $layout->set_markup("<small>$text</small>");
  $layout->set_font_description(
    Gtk2::Pango::FontDescription->from_string("sans 10")
  );
  return $layout;
}
sub small_text_lefted {
  my $w = shift;
  my $text = shift;
  my $width = shift || 82;
  my $layout = $w->create_pango_layout($text);
  $layout->set_width($width * PANGO_SCALE);
  $layout->set_wrap('word');
  $layout->set_alignment('left');
  $layout->set_spacing(1);
  $layout->set_markup("<small>$text</small>");
  $layout->set_font_description(
    Gtk2::Pango::FontDescription->from_string("sans 10")
  );
  return $layout;
}
sub xsmall_text_lefted {
  my $w = shift;
  my $text = shift;
  my $width = shift || 82;
  my $layout = $w->create_pango_layout($text);
  $layout->set_width($width * PANGO_SCALE);
  $layout->set_wrap('word');
  $layout->set_alignment('left');
  $layout->set_spacing(1);
  $layout->set_markup("<span size=\"xx-small\">$text</span>");
  $layout->set_font_description(
    Gtk2::Pango::FontDescription->from_string("sans")
  );
  return $layout;
}
sub timedistance_expose_handler {
  my $widget = shift;
  my $event = shift;
  my $app = shift;

  redraw_timedistance($app);

  return 0;
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
  #show_scrollbar($app);

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
  if(defined $app->{scrollbar_value}) {
    my $value = $app->{scrollbar_value};
    $planetinfo_da->window->draw_layout(
      $planetinfo_da->style->black_gc,
      0,
      83,
      small_text_centered($planetinfo_da,"<b>$value Ships</b>")
    );
  }
}

sub redraw_scrollbar {
  my $app = shift;
  if(defined $app->{source} && $app->{source}->{owner} eq "HUMAN" &&
    $app->{source}->{ships} > 0 && defined $app->{dest}) {
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
    $scrollbar->set_value(0);
    $scrollbar->set_sensitive(1);
    $app->{scrollbar_value} = 0;
  }
  else {
    $scrollbar->set_value(0);
    $scrollbar->set_sensitive(0);
    $app->{scrollbar_value} = undef;
  }
}

sub show_scrollbar {
  my $app = shift;

  if(!$app->{scrollbar_inited}) {
    if(defined $app->{source} && $app->{source}->{owner} eq "HUMAN" &&
      $app->{source}->{ships} > 0 && defined $app->{dest}) {
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
      $scrollbar->set_value(0);
      $scrollbar->set_sensitive(1);
      $app->{scrollbar_value} = 0;
    }
    else {
      $scrollbar->set_value(0);
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
  redraw_buttons($app);
}

sub redraw_buttons {
  my $app = shift;
  if(defined $app->{source} && $app->{source}->{owner} ne "HUMAN") {
    $launch->set_sensitive(0);
    $launch_all->set_sensitive(0);
    $ping->set_sensitive(0);
    $scan->set_sensitive(0);
    $constant_feed->set_sensitive(0);
  }
  elsif(defined $app->{source} && defined $app->{dest}) {
    # Source is HUMAN
    # ---------------
    if(defined $app->{scrollbar_value} && $app->{scrollbar_value} > 0) {
      # Scrollbar has a value, which means it was inited
      # ------------------------------------------------
      $launch->set_sensitive(1);
      $launch_all->set_sensitive(0);
      $ping->set_sensitive(0);
      $scan->set_sensitive(0);
      $constant_feed->set_sensitive(0);
    }
    elsif(!defined $app->{scrollbar_value}) {
      # Scrollbar not available
      # -----------------------
      $launch->set_sensitive(0);
      $launch_all->set_sensitive(0);
      $ping->set_sensitive(0);
      $scan->set_sensitive(0);
      $constant_feed->set_sensitive(0);
    }
    else {
      $launch->set_sensitive(0);
      $launch_all->set_sensitive(1);
      if($app->{source}->{ships}) {
        $ping->set_sensitive(1);
      }
      else {
        $ping->set_sensitive(0);
      }
      if($app->{source}->{ships} >= 3) {
        $scan->set_sensitive(1);
      }
      else {
        $scan->set_sensitive(0);
      }
      if(defined $app->{dest} && $app->{dest}->{owner} eq "HUMAN") {
        $constant_feed->set_sensitive(1);
      }
      else {
        $constant_feed->set_sensitive(0);
      }
    }
  }
  else {
    # no source, no dest, everything off
    # ----------------------------------
    $launch->set_sensitive(0);
    $launch_all->set_sensitive(0);
    $ping->set_sensitive(0);
    $scan->set_sensitive(0);
    $constant_feed->set_sensitive(0);
  }

}

sub create_menu_bar {
  my $window = shift;


  my $accel = Gtk2::AccelGroup->new;
  my $file = Gtk2::Menu->new();

  my $new = Gtk2::MenuItem->new('New');
  $new->signal_connect('activate' => \&new_game,$app);
  $new->add_accelerator('activate',$accel,ord('N'),'control-mask','visible');

  my $open = Gtk2::MenuItem->new('Open');
  $open->signal_connect('activate' => sub { load_game($app);  });
  $open->add_accelerator('activate',$accel,ord('O'),'control-mask','visible');

  my $save = Gtk2::MenuItem->new('Save');
  $save->signal_connect('activate' => sub { save_game($app);  });
  $save->add_accelerator('activate',$accel,ord('S'),'control-mask','visible');

  my $quit = Gtk2::MenuItem->new('Quit');
  $quit->signal_connect('activate' => sub { quit_game($app); });
  $quit->add_accelerator('activate',$accel,ord('Q'),'control-mask','visible');

  $app->{menus} = [$new,$open,$save];

  $file->append($new);
  $file->append($open);
  $file->append($save);
  $file->append(Gtk2::SeparatorMenuItem->new());
  $file->append($quit);

  $file->set_accel_path('<main>/File');

  my $options = Gtk2::Menu->new();
  #my $prefs = Gtk2::MenuItem->new('Preferences');
  #$prefs->signal_connect('activate' => \&show_preferences_dialog);
  #$options->append($prefs);

  my $snd = Gtk2::CheckMenuItem->new('Sound');
  $snd->set_active($app->{prefs}->{sound});
  $snd->signal_connect('activate' => sub { $app->{prefs}->{sound} = !$app->{prefs}->{sound} } );
  $options->append($snd);

  my $ab = Gtk2::CheckMenuItem->new('Auto-Battle');
  $ab->signal_connect('activate' => sub { $app->{prefs}->{autobattle} = !$app->{prefs}->{autobattle} } );
  $ab->set_active($app->{prefs}->{autobattle});
  $options->append($ab);

  $options->append(Gtk2::SeparatorMenuItem->new());
  my $fb = Gtk2::MenuItem->new('Faster Battles');
  $fb->signal_connect('activate' => sub { if($app->{prefs}->{speed}) {$app->{prefs}->{speed} -= 1000} } );
  $options->append($fb);

  my $sb = Gtk2::MenuItem->new('Slower Battles');
  $sb->signal_connect('activate' => sub { $app->{prefs}->{speed} += 1000 } );
  $options->append($sb);

  $options->append(Gtk2::SeparatorMenuItem->new());
  my $hs = Gtk2::MenuItem->new('High Scores');
  $hs->signal_connect('activate' => sub { show_high_scores(); } );
  $options->append($hs);
  #my $ss = Gtk2::MenuItem->new('Game Stats');
  #$ss->signal_connect('activate' => sub { print Dumper($ge->{stats}) } );
  #$options->append($ss);

  my $help = Gtk2::Menu->new();
  my $about = Gtk2::MenuItem->new('About');
  $about->signal_connect('activate' => \&show_about_dialog);
  $help->append($about);

  my $menubar = Gtk2::MenuBar->new();
  my $file_menu = Gtk2::MenuItem->new("File");
  $file_menu->set_submenu($file);
  my $options_menu = Gtk2::MenuItem->new("Options");
  $options_menu->set_submenu($options);
  my $help_menu = Gtk2::MenuItem->new("Help");
  $help_menu->set_right_justified(1);
  $help_menu->set_submenu($help);
  $menubar->append($file_menu);
  $menubar->append($options_menu);
  $menubar->append($help_menu);

  $window->add_accel_group($accel);

  return $menubar;
}

sub hex_to_color {
  my $color = shift;
  if($color =~ /^(..)(..)(..)$/) {
    my $r = $1;
    my $g = $2;
    my $b = $3;
    return Gtk2::Gdk::Color->new(
      hex($r) * 257,
      hex($g) * 257, 
      hex($b) * 257
    );
  }
}

sub show_menubar_dead_enemies {
  for my $e (@{$ge->{enemies}}) {
    if($e->{dead}) {
      my $headstone = lc($e->{type})."_headstone.xpm";
      my $de = Gtk2::ImageMenuItem->new("");
      $de->set_image(Gtk2::Image->new_from_file("$XPM_PATH/$headstone"));
      push(@{$app->{menu_dead_list}},$de);
      #$de->set_right_justified(1);
      $menubar->insert($de,2);
      $menubar->show_all();
    }
  }
}
sub scrub_menubar_dead_enemies {
  # Before we abandon current game, remove the dead enemies from the menubar
  # ------------------------------------------------------------------------
  if(@{$app->{menu_dead_list}}) {
    for my $de (@{$app->{menu_dead_list}}) {
      $de->destroy;
    }
    $menubar->show_all();
  }
  $app->{menu_dead_list} = [];

}

sub new_game {
  my $m = shift;
  my $app = shift;
  if($app->{ge}->{current_year} > 0 && !$app->{ge}->{gamesaved} && !$app->{ge}->{game_over}) {
    # Show warning dialog.
    if(show_abandon_game_dialog()) {
      return;
    }
  }
  scrub_menubar_dead_enemies();
  $app->{ge}->init_new();
  $app->{source} = undef;
  $app->{dest} = undef;
  $app->{last_source} = undef;
  $app->{last_dest} = undef;
  $app->{scrollbar_value} = undef;
  $app->{scrollbar_inited} = undef;
  $app->{button_pressed} = undef;

  # Update our pixmap
  # -----------------
  update_planetmap($app);

  # Redraw everything
  # -----------------
  $do_battle->sensitive(1);
  redraw_ge($app);
}

sub handle_launch {
  my $b = shift;
  my $app = shift;

  if(defined $app->{source} && defined $app->{dest} && $app->{scrollbar_value}) {
    # lets launch one
    # ---------------
    $app->{ge}->add_transport(
      $app->{source},
      $app->{dest},
      $app->{scrollbar_value}
    );

    # Play Launch Sound
    # -----------------
    play_sound('525launch.wav');

    # clear the state
    # ---------------
    $app->{source} = undef;
    $app->{dest} = undef;
    
    # redraw everything
    # -----------------
    redraw_ge($app);
  }
}
sub handle_launch_all {
  my $b = shift;
  my $app = shift;

  if(defined $app->{source} && defined $app->{dest}) {
    # lets launch one
    # ---------------
    $app->{ge}->add_transport(
      $app->{source},
      $app->{dest},
      $app->{source}->{ships}
    );

    # Play launch all sound
    # ---------------------
    play_sound('525launch.wav');

    # clear the state
    # ---------------
    $app->{source} = undef;
    $app->{dest} = undef;
    
    # redraw everything
    # -----------------
    redraw_ge($app);
  }
}
sub handle_scan {
  my $b = shift;
  my $app = shift;

  if(defined $app->{source} && defined $app->{dest}) {
    # Scanning is launching 1 ship, 3 times
    # -------------------------------------
    $app->{ge}->add_transport(
      $app->{source},
      $app->{dest},
      1
    );

    $app->{ge}->add_transport(
      $app->{source},
      $app->{dest},
      1
    );

    $app->{ge}->add_transport(
      $app->{source},
      $app->{dest},
      1
    );

    # Play ping sound
    # ---------------
    play_sound('142launchone.wav');

    # clear the state
    # ---------------
    $app->{source} = undef;
    $app->{dest} = undef;
    
    # redraw everything
    # -----------------
    redraw_ge($app);
  }
}
sub handle_launch_one {
  my $b = shift;
  my $app = shift;

  if(defined $app->{source} && defined $app->{dest}) {
    # lets launch one
    # ---------------
    $app->{ge}->add_transport(
      $app->{source},
      $app->{dest},
      1
    );

    # Play ping sound
    # ---------------
    play_sound('142launchone.wav');

    # clear the state
    # ---------------
    $app->{source} = undef;
    $app->{dest} = undef;
    
    # redraw everything
    # -----------------
    redraw_ge($app);
  }
}
sub handle_constant_feed {
  my $b = shift;
  my $app = shift;

  if(defined $app->{source} && defined $app->{dest}) {
    # Add the feed
    # ------------
    $app->{ge}->add_feed(
      $app->{source},
      $app->{dest}
    );

    # Play constant feed (dink) sound
    # -------------------------------
    play_sound('143constantfeed.wav');

    # now we need to update the icon to be a human forward icon
    # ---------------------------------------------------------
    $app->{source}->{is_feeding} = 1;

    # Now clear the state
    # -------------------
    $app->{source} = undef;
    $app->{dest} = undef;

    # Update the planetinfo
    # ---------------------
    update_planetmap($app);
    
    # Redraw everything
    # -----------------
    redraw_ge($app);
  }
}

sub handle_battle {
  my $b = shift;
  my $app = shift;


  # Clean out our state
  # -------------------
  $app->{source} = undef;
  $app->{dest} = undef;
  $app->{battling} = 1;

  # redraw everything
  # -----------------
  redraw_ge($app);

  # Play valkyries sound
  # --------------------
  play_sound('517valkyries.wav');

  # Disable Do Battle and other buttons
  # -----------------------------------
  $b->set_sensitive(0);
  for my $m (@{$app->{menus}}) {
    # Disable Save, New Game, Open
    $m->set_sensitive(0);
  }

  # Do Battle!
  # ----------
  $app->{ge}->do_battle();

  # Enable Do Battle button
  # -----------------------
  $app->{battling} = 0;
  $b->set_sensitive(1) unless($app->{ge}->{game_over});
  for my $m (@{$app->{menus}}) {
    # Re-enable Save, New Game, Open
    $m->set_sensitive(1);
  }
  #$app->{ge}->cheat_lost_game('MUTANTS');
  #$app->{ge}->cheat_own_enemy('GUBRU');
  #$app->{ge}->cheat_own_enemy('MUTANTS');
  #$app->{ge}->cheat_own_enemy('BOTS');
  #$app->{ge}->cheat_own_enemy('ARACHS');
  #$app->{ge}->cheat_own_enemy('NUKES');
  #$app->{ge}->cheat_own_enemy('BLOBS');
  #$app->{ge}->cheat_own_enemy('BOZOS');
  #$app->{ge}->cheat_own_enemy('CZIN');
  #update_planetmap($app);
  redraw_planetmap();

  if($app->{prefs}->{autobattle} && !$app->{ge}->{game_over}) {
    handle_battle($b,$app);
  }
}

sub redraw_ge {
  my $app = shift;

  redraw_scrollbar($app);
  redraw_planetmap($app);
  redraw_planetinfo($app);
  redraw_timedistance($app);
  redraw_buttons($app);
}

sub show_current_year {
  my $ge = shift;
  my $year = shift;
  my $app = shift->[0];

  redraw_timedistance($app);
  gui_wait();
}

sub show_fortify {
  my $ge = shift;
  my $transport = shift->[0];
  my $app = shift->[0];

  # Hi-lite the planet
  # ------------------
  draw_planet_select($planetmap_da,$transport->{dest});

  # Draw the fortify bubble
  # -----------------------
  draw_planet_fortify($planetmap_da,$transport);

  # Delay a few microseconds
  # ------------------------
  game_delay(60);  # 6/10ths?  Maybe 4/10th would be better
  
  # Redraw the planetmap
  # --------------------
  redraw_planetmap($app);
}

sub do_delay {
  #print "Delay\n";
  game_delay(60);
}

sub game_delay {
  my $val = shift;
  usleep($val * $app->{prefs}->{speed});
}

sub get_user_name {
  my $ret = '';
  my $d = Gtk2::Dialog->new(
    'You Won',
    $window,
    'modal',
    'gtk-ok' => 'ok',
    'gtk-cancel' => 'cancel',
  );
  my $label = Gtk2::Label->new("You have succeded where others have never failed.\nYour name will be added to the Hall of Victory.");
  my $entry = Gtk2::Entry->new();
  $entry->set_editable(1);
  $entry->set_text($ENV{USER});

  $d->vbox->add($label);
  $d->vbox->add($entry);
  $d->show_all();

  my $res = $d->run();
  if($res eq "ok") {
    $ret = $entry->get_text;
  }
  else {
    $ret = "I Forgot My Name";
  }
  $d->destroy;
  return $ret;
}
sub show_game_won {
  my $ge = shift;
  #print "Game won\n";

  # Process Scores
  # --------------
  my $ourscore = ($app->{ge}->{current_year} / scalar(@{$app->{ge}->{enemies}}));
  my $score = GalacticEmpire::Scores->new($SCOREFILE);
  if($score->check_high_score($ourscore)) {
    play_sound("513endofgame.wav");
    my $name = get_user_name();
    my $score_id = $score->add_score(
      $ourscore,
      $name,
      $app->{ge}->{current_year},
      join(', ',map { $_->{names} } @{$app->{ge}->{enemies}}),
      scalar(@{$app->{ge}->{enemies}})
    );
    my @scores = $score->scores();
    for my $s (@scores) {
      $s->{ours} = 1 if($s->{id} == $score_id);
    }
    $app->{scores} = \@scores;
    show_high_scores();
  }
  else {
    # not a high score
    play_sound("131winnorecord.wav");
    my $dialog = Gtk2::Dialog->new(
      'You Won',
      $window,
      'modal',
      'gtk-ok' => 'none'
    );

    $dialog->vbox->add(Gtk2::Label->new("Congratulations on your victory.\nUnfortunately, it was not a record."));
    $dialog->show_all;
    $dialog->run();
    $dialog->destroy();

    show_high_scores();
  }
}

sub show_high_scores {
  my $width = 375;
  my $height = 350;

  unless($app->{scores}) {
    # No scores, get them
    # -------------------
    my $score = GalacticEmpire::Scores->new($SCOREFILE);
    my @scores = $score->scores();
    $app->{scores} = \@scores;
  }

  # Setup the win-window
  # --------------------
  my $winner = Gtk2::Window->new('toplevel');
  $winner->set_title("High Scores");
  my $winner_da = Gtk2::DrawingArea->new();
  $winner_da->size(
    $width,
    $height
  );
  $winner_da->add_events([
    'exposure-mask',
  ]);
  $winner_da->signal_connect(
    'configure_event' => \&winner_map_configure_handler, $app
  );
  $winner_da->signal_connect(
    'expose_event' => \&winner_map_configure_handler, $app
  );
  $winner->add($winner_da);
  $winner->show_all();
  gui_wait();
}

sub winner_map_configure_handler {
  my $widget = shift;
  my $event = shift;
  my $app = shift;

  # Create the blank pixmap
  # -----------------------
  my $winner_map = Gtk2::Gdk::Pixmap->new(
    $widget->window,
    $widget->allocation->width,
    $widget->allocation->height,
    -1
  );

  $winner_map->draw_rectangle(
    $widget->style->white_gc,
    1,
    0,
    0,
    $widget->allocation->width,
    $widget->allocation->height
  );
  $winner_map->draw_pixbuf(
    $widget->style->white_gc,
    get_pixbuf("hall_of_fame.xpm"),
    0,
    0,
    0,
    0,
    $widget->allocation->width,
    192,
    'none',
    undef,
    undef
  );

  draw_high_scores($widget,$winner_map,$app->{scores});

  $widget->window->draw_drawable(
    $widget->style->fg_gc($widget->state),
    $winner_map,
    0,
    0,
    0,
    0,
    $widget->allocation->width,
    $widget->allocation->height
  );
  gui_wait();
}


sub draw_high_scores {
  my $winner_da = shift;
  my $winner_map = shift;
  my $scores = shift;
  
  my $start_height = 150;

  for my $s (sort { $a->{score} <=> $b->{score} } @$scores) {
    # User
    # ----
    my $user = $s->{ours} ? "<b>$s->{name}</b>" : $s->{name};
    $winner_map->draw_layout(
      $winner_da->style->black_gc,
      15,
      $start_height,
      small_text_lefted($winner_da,$user,120)
    );

    # Year
    # ----
    my $c = $s->{year};
    my $cy = int($c/10).".".($c%10);
    $winner_map->draw_layout(
      $winner_da->style->black_gc,
      128,
      $start_height,
      small_text_lefted($winner_da,$cy,40)
    );

    # Enemies
    # -------
    $winner_map->draw_layout(
      $winner_da->style->black_gc,
      215,
      $start_height,
      xsmall_text_lefted($winner_da,$s->{enemies},145)
    );

    $start_height += 20;
  }
}

sub redraw_game_won {
  my $winner_da = shift;
  my $winner_map = shift;
  $winner_da->window->draw_drawable(
    $winner_da->style->fg_gc($winner_da->state),
    $winner_map,
    0,
    0,
    0,
    0,
    $winner_da->allocation->width,
    $winner_da->allocation->height
  );
}



sub show_game_lost {
  my $dialog = Gtk2::Dialog->new(
    'You Failed',
    $window,
    'modal',
    'gtk-ok' => 'none'
  );

  $dialog->vbox->add(Gtk2::Label->new("You have snatched defeat from the jaws of\nvictory.  The Human race has perished."));
  $dialog->signal_connect(response => sub { $_[0]->destroy });
  $dialog->show_all;

}

sub gui_wait {
  while(Gtk2->events_pending()) {
    Gtk2->main_iteration();
  }
}

sub show_attack_setup {
  my $ge = shift;
  my $transport = shift->[0];
  my $app = shift->[0];
  my $tp = $transport->{dest};
  my $show_to_ships = 0;
  if(
    $transport->{owner} eq "HUMAN" ||
    $tp->{homeplanet} ||
    (($tp->{lastvisit} && ($ge->{current_year} - $tp->{lastvisit}) < 11)) ||
    $tp->{humanpings} >= 3 ||
    $ge->get_owned($tp,"HUMAN")
  ) {
    $show_to_ships = 1;
  }

  my $bubble = show_attack_bubble($transport);
  $app->{bubble_transport} = $transport;




  # The rest is text
  # ----------------
  # Attackers
  # ---------
  $planetmap_da->window->draw_layout(
    $planetinfo_da->style->black_gc,
    $bubble->{text_pos_x} + 7,
    $bubble->{text_pos_y} + 2,
    small_text_centered($planetinfo_da,"Attackers",57)
  );

  # Defenders
  # ---------
  $planetmap_da->window->draw_layout(
    $planetinfo_da->style->black_gc,
    $bubble->{text_pos_x} + 103,
    $bubble->{text_pos_y} + 2,
    small_text_centered($planetinfo_da,"Defenders",90)
  );

  # Attacker Ship Count
  # -------------------
  $planetmap_da->window->draw_layout(
    $planetinfo_da->style->black_gc,
    $bubble->{text_pos_x} + 52,
    $bubble->{text_pos_y} + 25,
    small_text_centered($planetinfo_da,"$transport->{ships}",40)
  );

  # Defender Ship Count
  # -------------------
  $planetmap_da->window->draw_layout(
    $planetinfo_da->style->black_gc,
    $bubble->{text_pos_x} + 107,
    $bubble->{text_pos_y} + 25,
    small_text_centered($planetinfo_da,"$tp->{ships}",40)
  );


  # Attack Type
  # -----------
  my $atype = $transport->{surprise} ? "Surprise Attack" : "Ships Attack";
  $planetmap_da->window->draw_layout(
    $planetinfo_da->style->black_gc,
    $bubble->{text_pos_x} + 10,
    $bubble->{text_pos_y} + 55,
    small_text_centered($planetinfo_da,$atype,180)
  );


  gui_wait();

  # We should save the bubble locations...
  # --------------------------------------
  $transport->{bubble} = $bubble;



  #small_text_centered($planetinfo_da,"Defender",90);
  #small_text_centered($planetinfo_da,"Defender",90);

  #$planetmap_da->window->draw_drawable(
  #  $planetmap_da->style->fg_gc($planetmap_da->state),
  #  $overlay,
  #  0,
  #  0,
  #  $bubble->{pos_x},
  #  $bubble->{pos_y},
  #  200,
  #  100
  #);

  # If the dest is human and a homeplanet, play I'm hit sound
  # ---------------------------------------------------------
  if($tp->{owner} eq "HUMAN" && $tp->{homeplanet}) {
    play_sound('516homehit.wav');
  }

  # Finally, delay a bit before we get started.
  # -------------------------------------------
  game_delay(10);
}

sub show_attack_bubble {
  my $transport = shift;
  my $tp = $transport->{dest};

  # Hi-lite the planet
  # ------------------
  draw_planet_select($planetmap_da,$tp);

  # Draw big bubble on planetmap
  # ----------------------------
  my $bubble = draw_planet_bubble($planetmap_da,$tp,'big');

  gui_wait();

  # Draw into the bubble attacker vs defender
  # 15,15 to 47,47 attacker icon
  # 153,15 to 185,47 defender icon
  # 7,2 to 65,15 word "Attacker"
  # 103,2 to 193,15 word "Defender"
  # At 52,25,92,40 draw attacker ship count
  # At 107,25 to 147,40 draw defender ship count
  # At 10,55 to 190,80 Draw ship surprise attack or Ships Attack
  # Ship count "NNNN Name"
  # Defender ship counts may not be shown.
  # Show ?? if unknown. No name on independents
  # ------------------------------------------------------------
  my $attackericon = lc($transport->{owner})."_icon_32x32.xpm";
  my $defendericon = lc($transport->{dest}->{owner})."_icon_32x32.xpm";

  # Draw Attacker Icon
  # ------------------
  $planetmap_da->window->draw_pixbuf(
    $planetmap_da->style->fg_gc($planetmap_da->state),
    get_pixbuf($attackericon),
    0,
    0,
    $bubble->{text_pos_x} + 15,
    $bubble->{text_pos_y} + 15,
    32,
    32,
    'none',
    undef,
    undef
  );


  # Draw Defender Icon
  # ------------------
  $planetmap_da->window->draw_pixbuf(
    $planetmap_da->style->fg_gc($planetmap_da->state),
    get_pixbuf($defendericon),
    0,
    0,
    $bubble->{text_pos_x} + 153,
    $bubble->{text_pos_y} + 15,
    32,
    32,
    'none',
    undef,
    undef
  );
  gui_wait();
  return $bubble;
}


sub show_attack_update {
  my $ge = shift;
  my $transport = shift->[0];
  my $app = shift->[0];
  my $bubble = $transport->{bubble};

  # No bubble, no setup
  return unless $bubble;

  my $tp = $transport->{dest};

  # Erase ship count area for attacker
  # ----------------------------------
  $planetmap_da->window->draw_rectangle(
    $planetmap_da->style->white_gc,
    1,
    $bubble->{text_pos_x} + 52,
    $bubble->{text_pos_y} + 25,
    40,
    15,
  );
  

  # Show new attacker ship count
  # ----------------------------
  $planetmap_da->window->draw_layout(
    $planetinfo_da->style->black_gc,
    $bubble->{text_pos_x} + 52,
    $bubble->{text_pos_y} + 25,
    small_text_centered($planetinfo_da,"$transport->{ships}",40)
  );

  gui_wait();

  # Erase defender count area
  # -------------------------
  $planetmap_da->window->draw_rectangle(
    $planetmap_da->style->white_gc,
    1,
    $bubble->{text_pos_x} + 107,
    $bubble->{text_pos_y} + 25,
    40,
    15,
  );

  # Show new defender ship count
  # ----------------------------
  $planetmap_da->window->draw_layout(
    $planetinfo_da->style->black_gc,
    $bubble->{text_pos_x} + 107,
    $bubble->{text_pos_y} + 25,
    small_text_centered($planetinfo_da,"$tp->{ships}",40)
  );
  gui_wait();


  # Delay just a few microseconds
  # -----------------------------
  game_delay(4);
}

sub show_attack_win {
  my $ge = shift;
  my $transport = shift->[0];
  my $app = shift->[0];

  my $tp = $transport->{dest};
  my $bubble = $transport->{bubble};

  return unless $bubble;

  # Determine who won
  # -----------------
  
  # If attackers won, and attackers a human, play a sound
  # -----------------------------------------------------
  if($transport->{owner} eq "HUMAN") {
    if($tp->{homeplanet}) {
      # If it was a home planet, play Capture Home sound
      # ------------------------------------------------
      play_sound('116capturehome.wav');
      
    }
    else {
      # Else it was just a planet
      # -------------------------
      play_sound('601victorygood.wav');
    }


  }
  # If nukes won, and it's a homeplanet, play Nuke Planet sound
  # -----------------------------------------------------------
  if($transport->{owner} eq "NUKES" && $tp->{homeplanet}) {
    # Play nuke sound
    play_sound('658nukestakehome.wav');
  }
    
  # If bozos won, and it's a homeplanet, play Bozo Planet sound
  # -----------------------------------------------------------
  if($transport->{owner} eq "BOZOS" && $tp->{homeplanet}) {
    # Play bozo sound
    play_sound('659bozostakehome.wav');
  }
  

  # Update the planet stats with those of the attacker
  # --------------------------------------------------
  update_planet($tp);

  my $status = '';
  # Show status message
  # -------------------
  if($transport->{nofight}) {
    # show "They give up without a fight"
    $status = "They give up without a fight";
  }
  else {
    # show "The Attackers are Victorious"
    $status = "The Attackers are Victorious";
  }

  # Blank out Attack Status
  # -----------------------
  $planetmap_da->window->draw_rectangle(
    $planetmap_da->style->white_gc,
    1,
    $bubble->{text_pos_x} + 10,
    $bubble->{text_pos_y} + 55,
    180,
    15,
  );

  # Attack Status
  # -------------
  $planetmap_da->window->draw_layout(
    $planetinfo_da->style->black_gc,
    $bubble->{text_pos_x} + 10,
    $bubble->{text_pos_y} + 55,
    small_text_centered($planetinfo_da,$status,180)
  );

  gui_wait();

  # Remove bubble_transport
  # -----------------------
  undef $app->{bubble_transport};

  # If HUMANs just lost a planet, make sure to remove the feed.
  # -----------------------------------------------------------
  $ge->remove_feed($tp);
  $tp->{is_feeding} = 0;

  # Delay for a little while 60 or 120
  # ----------------------------------
  game_delay(120);
 
  # Redraw planetmap
  # ----------------
  redraw_planetmap($app);

  # Show all of this at 3,55 to 198,80
  # ----------------------------------
}
sub show_attack_hold {
  my $ge = shift;
  my $transport = shift->[0];
  my $app = shift->[0];

  my $tp = $transport->{dest};
  my $bubble = $transport->{bubble};

  return unless $bubble;

  if($transport->{owner} eq "HUMAN") {
    # If attackers lost and were human, play Bummer sound, unless it was a ping
    # -------------------------------------------------------------------------
    if(!$transport->{ping}) {
      # play bummer
      play_sound('520bummer.wav');
    }
  }
  
  my $status = 'The Defenders Held';

  # Blank out Attack Status
  # -----------------------
  $planetmap_da->window->draw_rectangle(
    $planetmap_da->style->white_gc,
    1,
    $bubble->{text_pos_x} + 10,
    $bubble->{text_pos_y} + 55,
    180,
    15,
  );

  # Attack Status
  # -------------
  $planetmap_da->window->draw_layout(
    $planetinfo_da->style->black_gc,
    $bubble->{text_pos_x} + 10,
    $bubble->{text_pos_y} + 55,
    small_text_centered($planetinfo_da,$status,180)
  );

  gui_wait();

  # Remove bubble_transport
  # -----------------------
  undef $app->{bubble_transport};


  # Delay for a little while 60 or 120
  # ----------------------------------
  game_delay(120);
 
  # Redraw planetmap
  # ----------------
  redraw_planetmap($app);

  # Show all of this at 3,55 to 198,80
  # ----------------------------------
}

sub show_enemy_dead {
  my $ge = shift;
  my $ge_args = shift;
  my $my_args = shift;

  my $e = $ge_args->[0];

  # We've killed someone
  # --------------------
  my @infomsg = (
    "$e->{names} Croak!",
    "$e->{names} have been wiped out!",
    "$e->{names} bite the dust!",
    "$e->{names} have been eliminated!",
    "$e->{names} choke and die!",
    "$e->{names} are dead meat!",
  );
  my $i = GalacticEmpire::get_rand(5);
  my $infomsg = $infomsg[$i];
  my $icon = lc($e->{type})."_icon_32x32.xpm";
  
  my $h = int(((PLANETROWS*PLANETHEIGHT) - 52)/2);
  my $w = int(((PLANETCOLS*PLANETWIDTH) - 280)/2);


  # Draw filled white box
  # ---------------------
  $planetmap_da->window->draw_rectangle(
    $planetmap_da->style->white_gc,
    1,
    $w,
    $h,
    280,
    52,
  );
  # Draw black outline
  # ------------------
  $planetmap_da->window->draw_rectangle(
    $planetmap_da->style->black_gc,
    0,
    $w,
    $h,
    280,
    52,
  );


  # Draw enemy icon
  # ---------------
  $planetmap_da->window->draw_pixbuf(
    $planetmap_da->style->fg_gc($planetmap_da->state),
    get_pixbuf($icon),
    0,
    0,
    $w+10,
    $h+10,
    32,
    32,
    'none',
    undef,
    undef
  );

  # Draw text
  # ---------
  $planetmap_da->window->draw_layout(
    $planetinfo_da->style->black_gc,
    $w+52,
    $h+18,
    small_text_lefted($planetinfo_da,$infomsg,228)
  );


  # Add their icon to the menubar
  # -----------------------------
  my $headstone = lc($e->{type})."_headstone.xpm";
  my $de = Gtk2::ImageMenuItem->new("");
  $de->set_image(Gtk2::Image->new_from_file("$XPM_PATH/$headstone"));
  push(@{$app->{menu_dead_list}},$de);
  #$de->set_right_justified(1);
  $menubar->insert($de,2);
  $menubar->show_all();

  # Redraw the menubar
  # ------------------
  gui_wait();

  # Pause to savor the victory
  # --------------------------
  game_delay(250);
  #my $f = <STDIN>;

  # Redraw the map
  # --------------
  redraw_planetmap($app);
  gui_wait();
}
  
sub show_preferences_dialog {

}

sub show_about_dialog {
  my $dialog = Gtk2::Dialog->new(
    'About Galactic Empire',
    $window,
    'modal',
    'gtk-ok' => 'none'
  );

  $dialog->vbox->add(Gtk2::Image->new_from_file("$XPM_PATH/about_ge.xpm"));
  $dialog->signal_connect(response => sub { $_[0]->destroy });
  $dialog->show_all;
}

sub save_game {
  my $app = shift;

  # Save file as dialog
  # -------------------
  my $w = Gtk2::FileChooserDialog->new("Save Game File",$window,'save');
  my $ff = Gtk2::FileFilter->new;
  $ff->add_pattern('*.ge');
  $w->add_filter($ff);
  $w->set_current_name("saved_game.ge");
  $w->add_button('gtk-cancel','cancel');
  $w->add_button('gtk-save','ok');
  my $r = $w->run;
  if($r eq "ok") {
    my $file = $w->get_filename;
    my $cursor = Gtk2::Gdk::Cursor->new('watch');
    $w->window->set_cursor($cursor);
    #$w->get_window->set_cursor($cursor);
    gui_wait();
    $ge->save($file);
  }
  else {

  }
  $w->destroy;

}

sub load_game {
  my $app = shift;
  if($app->{ge}->{current_year} > 0 && !$app->{ge}->{gamesaved} && !$app->{ge}->{game_over}) {
    # Show warning dialog.
    if(show_abandon_game_dialog()) {
      return;
    }
    scrub_menubar_dead_enemies();
  }
  my $w = Gtk2::FileChooserDialog->new("Open Game File",$window,'open');
  my $ff = Gtk2::FileFilter->new;
  $ff->add_pattern('*.ge');
  $w->add_filter($ff);
  $w->add_button('gtk-cancel','cancel');
  $w->add_button('gtk-open','ok');
  my $r = $w->run;
  if($r eq "ok") {
    my $file = $w->get_filename;
    my $cursor = Gtk2::Gdk::Cursor->new('watch');
    undef $ge;
    $ge = GalacticEmpire->load($file);
    $app->{ge} = $ge;

    $ge->set_callback('current_year',\&show_current_year,$app);
    $ge->set_callback('fortify',\&show_fortify,$app);
    $ge->set_callback('delay',\&do_delay,$app);
    $ge->set_callback('game_won',\&show_game_won,$app);
    $ge->set_callback('game_lost',\&show_game_lost,$app);
    $ge->set_callback('attack_setup',\&show_attack_setup,$app);
    $ge->set_callback('attack_update',\&show_attack_update,$app);
    $ge->set_callback('attackers_win',\&show_attack_win,$app);
    $ge->set_callback('defenders_win',\&show_attack_hold,$app);
    $ge->set_callback('enemy_dead',\&show_enemy_dead,$app);
    #init_planetmap_signals($app);
    #init_timedistance_signals($app);
    #init_planetinfo_signals($app);
    #init_scrollbar_signals($app);
    #init_button_signals($app);

    $w->destroy;
    show_menubar_dead_enemies();
    update_planetmap($app);
    redraw_ge($app);
    gui_wait();
  }
  else {
    $w->destroy;
  }
}
sub show_abandon_game_dialog {
  my $d = Gtk2::MessageDialog->new(
    $window,
    'modal',
    'warning',
    'ok-cancel',
    'All progress on existing game will be lost.',
  );

  my $res = $d->run();
  if($res eq "cancel") {
    $d->destroy;
    return 1;
  }
  $d->destroy;
  return 0;
}

sub quit_game {
  my $app = shift;
  if($app->{ge}->{current_year} > 0 && !$app->{ge}->{gamesaved} && !$app->{ge}->{game_over}) {
    # Show warning dialog.
    if(show_abandon_game_dialog()) {
      return;
    }
  }
  Gtk2->main_quit;
}
