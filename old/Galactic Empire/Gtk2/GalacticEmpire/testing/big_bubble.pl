#!/usr/bin/perl
#

use strict;
use Gtk2;
use Gtk2::Pango;
use constant PLANETROWS => 27;
use constant PLANETCOLS => 32;
use constant PLANETWIDTH => 16;
use constant PLANETHEIGHT => 16;

my $app = {
  total_planets => PLANETROWS * PLANETCOLS,
  source => undef,
  dest => undef,
  planets => [],
};

Gtk2->init;
my %popups = ();
for my $file (qw(
  small_bottom_left
  small_bottom_right
  small_top_left
  small_top_right
  big_bottom_left
  big_bottom_right
  big_top_left
  big_top_right
)) {
  my ($size,$tb,$lr) = split(/\_/,$file);
  $popups{$size}{$tb}{$lr} = Gtk2::Gdk::Pixbuf->new_from_file("xpms/$file.xpm");
}
my $window = Gtk2::Window->new('toplevel');
my $drawing = Gtk2::DrawingArea->new();
my $planetmap;
$drawing->size(
  PLANETCOLS*PLANETWIDTH,
  PLANETROWS*PLANETHEIGHT
);
$drawing->add_events([
  'exposure-mask',
  'pointer-motion-mask',
  'pointer-motion-hint-mask',
  'button-press-mask',
  'button-release-mask'
]);

$drawing->signal_connect(
  'expose_event' => \&expose_handler, $app
);
$drawing->signal_connect(
  'motion_notify_event' => \&motion_handler, $app
);
$drawing->signal_connect(
  'configure_event' => \&configure_handler, $app
);
$drawing->signal_connect(
  'button_press_event' => \&button_handler, $app
);
$drawing->signal_connect(
  'button_release_event' => \&button_handler, $app
);

#$button->signal_connect(clicked => sub { Gtk2->main_quit });
$window->signal_connect(destroy => sub { Gtk2->main_quit });
$window->add($drawing);
$window->show_all;
Gtk2->main;

sub configure_handler {
  my $widget = shift;
  my $event = shift;
  my $app = shift;
  $planetmap = Gtk2::Gdk::Pixmap->new(
    $widget->window,
    $widget->allocation->width,
    $widget->allocation->height,
    -1
  );

  my $map_color = Gtk2::Gdk::Color->new(221 * 257,221 * 257, 221 * 257);
  #my $map_color = Gtk2::Gdk::Color->parse('purple');

  my $map_gc = Gtk2::Gdk::GC->new($widget->window);
  $map_gc->set_rgb_bg_color($map_color);
  $map_gc->set_rgb_fg_color($map_color);
  $planetmap->draw_rectangle(
    $map_gc,
    1,
    0,
    0,
    $widget->allocation->width,
    $widget->allocation->height
  );

  my $humanplanet = Gtk2::Gdk::Pixbuf->new_from_file(
    "human_planet.xpm"
  );
  for (my $i = 0; $i < $app->{total_planets}; $i++) {
    $app->{planets}[$i] ||= {};
    $app->{planets}[$i]{x} = int(($i % PLANETCOLS)) * PLANETWIDTH;
    $app->{planets}[$i]{y} = int(($i / PLANETCOLS)) * PLANETHEIGHT;
    $app->{planets}[$i]{id} = $i;
    $app->{planets}[$i]{type} = ($i % 3) ? 'NOPLANET' : 'HUMAN';
  }
  for (my $i = 0; $i < $app->{total_planets}; $i++) {
    if($app->{planets}[$i]{type} eq "HUMAN") {
      $planetmap->draw_pixbuf(
        $map_gc,
        $humanplanet,
        0,
        0,
        $app->{planets}[$i]{x},
        $app->{planets}[$i]{y},
        PLANETWIDTH,
        PLANETHEIGHT,
        'none',
        undef,
        undef
      );
    }
  }
  return 1; 
}

sub expose_handler {
  my $widget = shift;
  my $event = shift;
  my $app = shift;

  $widget->window->draw_drawable(
    $widget->style->fg_gc($widget->state),
    $planetmap,
    $event->area->x,
    $event->area->y,
    $event->area->x,
    $event->area->y,
    $event->area->width,
    $event->area->height
  );

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
  my $planet = shift;

  my $bubble = draw_planet_bubble($widget,$planet,'small');
  draw_bubble_text($widget,$bubble,"78 ships fortify");

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

  my $bubble = {};
  my $pixbuf = $popups{$size}{$tb}{$lr};

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
    $pixbuf = $popups{$size}{$tb}{$lr};
    $pos_y = $planet->{y}+8;
    $bubble->{text_pos_y} = $pos_y+23;
  }
  if( ($planet->{x}+8+$width) > $bound_width ) {
    # gotta be right
    $lr = "right";
    $pixbuf = $popups{$size}{$tb}{$lr};
    $pos_x = ($planet->{x}-$width)+8;
    $bubble->{text_pos_x} = $pos_x+8;
  }
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

sub button_handler {
  my $widget = shift;
  my $event = shift;
  my $app = shift;

  my $x = $event->type;
  if($event->button == 1) {
    my ($wap,$x,$y,$mask) = $event->window->get_pointer();
    if($event->type eq 'button-press') {
      redraw_planetmap($widget);
      $app->{source} = undef;
      $app->{dest} = undef;

      my $planet = get_planet($x,$y,$app);

      if($planet) {
        $app->{button_pressed} = 1;
        $app->{source} = $planet;
        draw_planet_select($widget,$planet);
        draw_planet_fortify($widget,$planet);
      }
    }
    elsif($event->type eq 'button-release') {
      redraw_planetmap($widget);
      my $planet = get_planet($x,$y,$app);
      $app->{button_pressed} = 0;
      if($planet && $app->{source}{id} != $planet->{id}) {
        $app->{dest} = $planet;
        draw_planet_select($widget,$app->{source});
        draw_planet_select($widget,$app->{dest});
        draw_planet_line($widget,$app->{source},$app->{dest});
      }
      elsif($app->{source}) {
        draw_planet_select($widget,$app->{source});
      }
    }

  }

  return 1;
}

sub redraw_planetmap {
  my $widget = shift;
  $widget->window->draw_drawable(
    $widget->style->fg_gc($widget->state),
    $planetmap,
    0,
    0,
    0,
    0,
    $widget->allocation->width,
    $widget->allocation->height
  );
}

sub get_planet {
  my $x = shift;
  my $y = shift;
  my $app = shift;
  my $row = int($y / PLANETHEIGHT);
  my $col = int($x / PLANETWIDTH);
  my $p = $app->{planets}[($row * PLANETCOLS) + $col];
  if(defined $p && $p->{type} eq "NOPLANET") {
    return undef;
  }
  return $p;
}

sub motion_handler {
  my $widget = shift;
  my $event = shift;
  my $app = shift;

  if($app->{button_pressed} && $app->{source}) {
    redraw_planetmap($widget);
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
