#include <gtk/gtk.h>

void CloseTheApp ( GtkWidget * window, gpointer data) {
  gtk_main_quit();
}

gboolean EventHandler (GtkWidget * window, GdkEvent * event, gpointer data) {
  switch ( event->type ) {
    case GDK_CONFIGURE:
      g_print("The window is being reconfigured\n");
      break;
    case GDK_EXPOSE:
      g_print("The window contents were redrawn\n");
      break;
    case GDK_ENTER_NOTIFY:
      g_print("The mouse entered the window\n");
      break;
    case GDK_LEAVE_NOTIFY:
      g_print("The mouse left the window\n");
      break;
    case GDK_DELETE:
      g_print("Uh oh - the user killed the window\n");
      break;
    default:
      break;
  }
  return FALSE;
}

void CreateMainGalaxyWindow() {
  GtkWidget * window;
  GtkWidget * table;
  GtkWidget * Launch_One;
  GtkWidget * Launch_All;
  GtkWidget * Constant_Feed;
  GtkWidget * Do_Battle;

  Launch_One = gtk_button_new_with_label("Launch One");
  Launch_All = gtk_button_new_with_label("Launch All");
  Constant_Feed = gtk_button_new_with_label("Constant Feed");
  Do_Battle = gtk_button_new_with_label("Do Battle");

  table = gtk_table_new(480,640,FALSE);
  gtk_table_attach_defaults(GTK_TABLE(table),Launch_One,500,640,200,230);
  gtk_table_attach_defaults(GTK_TABLE(table),Launch_All,500,640,233,263);
  gtk_table_attach_defaults(GTK_TABLE(table),Constant_Feed,500,640,266,296);
  gtk_table_attach_defaults(GTK_TABLE(table),Do_Battle,500,640,299,329);

  window = gtk_window_new ( GTK_WINDOW_TOPLEVEL );
  gtk_window_set_default_size( GTK_WINDOW(window), 640, 480);
  gtk_container_add ( GTK_CONTAINER(window),table);
  gtk_widget_show_all(window);
  gtk_signal_connect( 
    GTK_OBJECT ( window ),
    "event",
    GTK_SIGNAL_FUNC( EventHandler ),
    NULL
  );
  gtk_signal_connect( 
    GTK_OBJECT ( window ),
    "destroy",
    GTK_SIGNAL_FUNC( CloseTheApp ),
    NULL
  );

}
  

gint main ( gint argc, gchar * argv[] ) {
  gtk_init ( &argc, &argv );
  CreateMainGalaxyWindow();
  gtk_main();
  return 0;
}
