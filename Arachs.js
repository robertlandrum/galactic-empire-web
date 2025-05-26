function Arachs(app) {
  this.type = 'ARACHS';
  this.name = 'Arach';
  this.names = 'Arachs';
  this.home = undefined;
  this.dead = false;
  this.planet_count = 0;
  this.enemy = undefined;
  this.enemy_type = undefined;
  this.homelost = false;
  this.app = app;
};


Arachs.prototype.move = function () {
  if(this.dead) {
    return false;
  }

  var agress = 0;
  var acount = 0;
  var year = this.app.ge.current_year;
  var d = 0;
  var weight = 0;
  var i;
  var p;
  var moves = [];
  var ship_pool = 0;
 

  if(year == 0) {
    pickEnemyRandomly(this);
    this.planet_count = 1;
  }

  acount = planetCount(this);

  if(acount > this.planet_count || year <= 80) {
    agress = 1;
  }
  if(acount < this.planet_count) {
    agress = -1;
  }

  if(this.enemy.dead) {
    while(this.enemy.dead) {
      pickEnemyRandomly(this);
    }
  }

  if(this.home.owner == this.type) {
    // Plan 4 moves
    // ------------
    moves = [];

    for (i in this.app.ge.planets) {
      p = this.app.ge.planets[i];
      if(!p.isPlanet()) {
        continue;
      }
      if(p.owner == this.type) {
        continue;
      }
      if(p.id == this.home.id) {
        continue;
      }

      d = calcDSquare(this.home,p);
      weight = 0;

      if(agress < 0) {
        weight = Math.floor(((p.isIndependent() ? 1 : 0) * 40) / d);
      }
      else if(agress == 0) {
        weight = ((p.owner == this.enemy_type) || (p.owner != this.type && p.hasOwned(this))) ? 3 : 1;
        weight *= (year > 90 && p.isIndependent()) ? 0 : 1;
        weight = Math.floor((weight * (90 + Math.floor(year / 2))) / d);
      }
      else if(agress > 0) {
        weight = p.owner == this.enemy_type ? 3 : 1;
        weight *= (year > 90 && p.isIndependent()) ? 0 : 1;
        weight = Math.floor((weight * (200 + Math.floor(year / 2))) / d);
      }
      weight += getRand(5);

      if(weight > 0) {
        moves.push({
          weight: weight,
          planet: p
        });
        
        moves = moves.sort(function (a,b) { return b.weight - a.weight });
        if(moves.length > 4) {
          moves = moves.splice(0,4);
        }
      }
    }

    // Moves are planned.  Now determined ships.
    // -----------------------------------------

    var ships = this.home.ships;
    ship_pool = 0;

    if(agress < 0) {
      ship_pool = Math.floor(ships / 4);
    }
    else if(agress == 0) {
      ship_pool = year < 100 ?
        Math.floor((ships * 3) / 5) : 
        Math.floor((ships * 1) / 2);
    }
    else if(agress > 0) {
      ship_pool = year < 100 ? 
        Math.floor((ships * 3) / 4) :
        Math.floor((ships * 3) / 5);
    }

    this.app.ge.processMoves(this.home,moves,ship_pool,{
      known_threshold_multiplier: 1.33,
      unknown_thresholds: [
        (10 + Math.floor(year / 2)),
        100
      ]
    });
  }
  else {
    // We have no home
    // ---------------
    getNewHome(this);
    this.homelost = true;
  }

  for (i in this.app.ge.planets) {
    var p = this.app.ge.planets[i];

    if(p.owner != this.type) {
      continue;
    }
    if(p.id == this.home.id) {
      continue;
    }
    var home_threshold = 0;
    var ext_threshold = 0;
    var j = 0;

    if(agress < 0) {
      j = getRand(2);
      if(j == 0) {
        home_threshold = 5;
        ext_threshold = 0;
      }
      else {
        home_threshold = p.ships;
      }
    }
    else if(agress == 0) {
      j = getRand(6);
      if(j == 0 || j == 5) {
        home_threshold = 10;
      }
      else if(j == 1) {
        home_threshold = 20;
      }
      else if(j == 2) {
        home_threshold = p.ships;
      }
      else {
        home_threshold = p.ships;
        ext_threshold = home_threshold - 6;
      }
    }
    else if(agress > 0) {
      j = getRand(6);
      if(j == 0 || j == 6) { // 6????? XXX FIXME
        home_threshold = 10;
      }
      else if(j == 1) {
        home_threshold = Math.floor((p.ships * 1) / 3);
      }
      else if(j == 2) {
        home_threshold = Math.floor((p.ships * 2) / 3);
        ext_threshold = home_threshold - 10;
      }
      else {
        home_threshold = p.ships;
        ext_threshold = home_threshold;
      }
    }

    // home_threshold is num ships to keep on planet
    // ---------------------------------------------
    if(p.ships > home_threshold) {
      var ships_to_move = p.ships - home_threshold;
      if(ships_to_move > 0) {
        var ds = calcDSquare(p,this.home);
        if(ds < (150 + Math.floor(ships_to_move / 5))) {
          this.app.ge.addTransport(p,this.home,ships_to_move);
        }
      }
    }

    if(ext_threshold > 0) {
      ship_pool = ext_threshold;
      var extmoves = [];

      for (var k in this.app.ge.planets) {
        var p2 = this.app.ge.planets[k];
        if(!p2.isPlanet()) {
          continue;
        }
        if(p2.isIndependent() && year > 80) {
          continue;
        }
        if(p2.id == this.home.id) {
          continue;
        }
        if(p.id == p2.id) {
          continue;
        }
        d = calcDSquare(p,p2);
        if(d == 0) {
          continue;
        }
        weight = Math.floor(50 / d);
        weight += getRand(5);

        if(weight > 0) {
          extmoves.push({
            weight: weight,
            planet: p2
          });

          extmoves = extmoves.sort(function (a,b) { return b.weight - a.weight });
          if(extmoves.length > 3) {
            extmoves = extmoves.splice(0,3);
          }
        }
      }

      this.app.ge.processMoves(p,extmoves,ship_pool,{
        known_threshold_multiplier: 1.33,
        unknown_thresholds: [
          (15 + Math.floor(year / 3)),
          120
        ]
      });
    }
  }
};
