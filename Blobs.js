function Blobs(app) {
  this.type = 'BLOBS';
  this.name = 'Blob';
  this.names = 'Blobs';
  this.home = undefined;
  this.dead = false;
  this.planet_count = 0;
  this.enemy = undefined;
  this.enemy_type = undefined;
  this.app = app;
};


Blobs.prototype.move = function () {
  if(this.dead) {
    return false;
  }
  for (var i in this.app.ge.planets) {
    var p = this.app.ge.planets[i];
    if(p.owner == this.type) {
      for (var o in this.app.ge.planets) {
        var tp = this.app.ge.planets[o];
        if(tp.owner != this.type && tp.homeplanet && (tp.ships * 2) < p.ships) {
          if(getRand(3) == 0) {
            continue;
          }
          var ships_to_send = tp.ships * 2;
          ships_to_send += calcTime(p,tp);
          
          // Dont send more than we have
          // ---------------------------
          if(ships_to_send < p.ships) {
            this.app.ge.addTransport(p,tp,ships_to_send);
          }
        }
      }
    }
  }
};
