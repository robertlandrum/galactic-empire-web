function Czins(app) {
  this.type = 'CZIN';
  this.name = 'Czin';
  this.names = 'Czins';
  this.home = undefined;
  this.dead = false;
  this.planet_count = 0;
  this.enemy = undefined;
  this.enemy_type = undefined;
  this.homelost = false;
  this.app = app;
};


Czins.prototype.move = function () {
  if(this.dead) {
    return false;
  }
  var agress = 0;
  var ccount = 0;
  var year = this.app.ge.current_year;
  var moves = [];
  var i;
  var d;
  var p;
  var j;
  var weight = 0;
  var ship_pool = 0;


  if(year == 0) {
    pickEnemyClosest(this);
    this.planet_count = 1;
  }

  ccount = planetCount(this);
  if(ccount > (this.planet_count + (this.homelost ? 1 : 0)) || year <= 60) {
    agress = 1;
  }

  if(ccount < this.planet_count) {
    agress = -1;
  }
  this.planet_count = ccount;
  if(this.enemy.dead) {
    while(this.enemy.dead) {
      pickEnemyClosest(this);
    }
  }

  if(this.home.owner == this.type) {
    // Plan 3 moves
    // ------------

    for (i in this.app.ge.planets) {
      p = this.app.ge.planets[i];
      if(!p.isPlanet()) {
        continue;
      }
      if(p.owner == this.type) {
        continue;
      }

      d = calcDSquare(this.home,p);
      weight = 0;

      if(agress < 0) {
        weight = p.isIndependent() ? 0 : Math.floor(30 / d);
      }
      else if(agress == 0) {
        weight = Math.floor((p.owner == this.enemy_type ? 3 : 1) *
          ((year > 150 && p.isIndependent()) ? 0 : 1) *
          (120 + Math.floor(year / 2)) / d);
      }
      else if(agress > 0) {
        weight = Math.floor((p.owner == this.enemy_type ? 3 : 1) *
          ((year > 180 && p.isIndependent()) ? 0 : 1) *
          (200 + Math.floor(year / 2)) / d);
      }

      weight += getRand(10);

      if(weight > 0) {
        moves.push({
          weight: weight,
          planet: p
        });
        
        moves = moves.sort(function (a,b) { return b.weight - a.weight });
        if(moves.length > 3) {
          moves = moves.splice(0,3);
        }
      }
    }

    // Figure out which ships to send
    // ------------------------------
    var ships = this.home.ships;
    ship_pool = 0;
    if(agress < 0) {
      ship_pool = 0;
    }
    else if(agress == 0) {
      ship_pool = Math.floor((ships * 1) / 2);
    }
    else if(agress > 0) {
      ship_pool = Math.floor((ships * 4) / 5);
    }

    this.app.ge.processMoves(this.home,moves,ship_pool,{
      min_ships: 10,
      known_threshold_multiplier: 1.50,
      unknown_thresholds: [
        (30 + Math.floor(year / 2)),
        200
      ]
    });
  }
  else {
    // Get new home
    // ------------
    getNewHome(this);
    this.homelost = true;
  }

  // Collect ships from outlying planets
  // -----------------------------------
  for (i in this.app.ge.planets) {
    p = this.app.ge.planets[i];
    if(p.owner != this.type) {
      continue;
    }
    if(p.id == this.home.id) {
      continue;
    }
    var home_threshold = 0;
    var ext_threshold = 0;
    if(agress < 0) {
      home_threshold = 5;
      ext_threshold = 0;
    }
    else if(agress == 0) {
      j = getRand(5);
      if(j == 0 || j == 5) {
        home_threshold = 20;
      }
      else if(j == 1 || j == 2) {
        home_threshold = p.ships;
      }
      else if(j == 3 || j == 4) {
        home_threshold = p.ships;
        ext_threshold = home_threshold - 10;
      }
    }
    else if(agress > 0) {
      j = getRand(6);
      if(j == 0 || j == 6) {
        home_threshold = Math.floor((p.ships * 4) / 5);
      }
      else {
        home_threshold = p.ships;
        ext_threshold = home_threshold - 10;
      }
    }

    if(p.ships > home_threshold) {
      if(getRand(1) == 1) {
        continue;
      }
      var ships_to_move = p.ships - home_threshold;
      if(ships_to_move > 0) {
        d = calcDSquare(p,this.home);
        if(d < (140 + Math.floor(ships_to_move / 5))) {
          this.app.ge.addTransport(p,this.home,ships_to_move);
        }
      }
    }

    if(ext_threshold > 0) {
      var ship_pool = ext_threshold;
      moves = [];
      for(var k in this.app.ge.planets) {
        var p2 = this.app.ge.planets[k];
        if(!p2.isPlanet()) {
          continue;
        }
        if(p2.owner == this.type) {
          continue;
        }
        if(p2.isIndependent() && year > 80) {
          continue;
        }
        if(p2.id == this.home.id) {
          continue;
        }
        if(p2.id == p.id) {
          continue;
        }

        d = calcDSquare(p,p2);
        if(d > 0) {
          weight = Math.floor(50 / d);
          weight += getRand(10);

          if(weight > 0) {
            moves.push({
              weight: weight,
              planet: p2,
            });
            moves = moves.sort(function (a,b) { return a.weight - b.weight });
            if(moves.length > 3) {
              moves = moves.splice(0,3);
            }
          }
        }
      }

      this.app.ge.processMoves(p,moves,ship_pool,{
        min_ships: 10,
        known_threshold_multiplier: 1.50,
        unknown_thresholds: [
          (15 + Math.floor(year / 3)),
          100
        ]
      });
    } // end ext_threshold
  } // end planet loop

};
