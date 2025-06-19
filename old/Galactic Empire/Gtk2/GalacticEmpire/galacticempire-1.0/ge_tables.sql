CREATE TABLE planets (
  id            int,
  x             int,
  y             int,
  row           int,
  col           int,
  owner         text,
  lastvisit     int,
  homeplanet    int,
  everowned     int,
  humanpings    int,
  industry      int,
  ships         int,
  is_feeding    int,
  owned         text
);

CREATE TABLE feeds (
  source        int,
  dest          int

);
CREATE TABLE enemies (
  dead          int,
  names         text,
  name          text,
  enemy_type    text,
  planet_count  int,
  type          text,
  home          int,

  homelost      int,
  next          int,
  stage         int,
  wait          int,
  search        text,
  ndiv          int
);
CREATE TABLE transports (
  source        int,
  dest          int,
  owner         text,
  ships         int,
  ping          int,
  timeleft      int
);

CREATE TABLE galacticempire (
  game_over     int,
  total_planets int,
  total_enemies int,
  current_year  int,
  human_home    int
);

