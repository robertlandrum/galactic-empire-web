function Gubrus(app) {
  this.type = 'GUBRU';
  this.name = 'Gubru';
  this.names = 'Gubrus';
  this.home = undefined;
  this.dead = false;
  this.planet_count = 0;
  this.enemy = undefined;
  this.enemy_type = undefined;
  this.app = app;
};

Gubrus.prototype.move = function () {
  var gcount = 0;
  var agress = 0;
  var year = this.app.ge.current_year;
  var i;
  var p;
  var weight = 0;
  var d;
  var moves = [];
  var ship_pool = 0;


  if(this.dead) {
    return false;
  }

  if(year == 0) {
    pickEnemyRandomly(this);
    this.planet_count = 1;
  }

  gcount = planetCount(this);

  if(gcount > this.planet_count || year <= 80) {
    agress = 1;
  }
  if(gcount < this.planet_count) {
    agress = -1;
  }

  // Get ourselves a new enemy
  // -------------------------
  if(this.enemy.dead) {
    while(this.enemy.dead) {
      pickEnemyRandomly(this);
    }
  }

  // See if we own our home planet
  // -----------------------------
  if(this.home.owner == this.type) {
    moves = [];

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
        weight = p.isIndependent() ? 1 : 0;
        weight = Math.floor((weight * 40) / d);
      }
      else if(agress > 0) {
        weight = p.owner == this.enemy_type ? 3 : 1;
        weight *= p.isIndependent() ? 2 : 1;
        weight = Math.floor((weight * (200 + Math.floor(year / 2))) / d);
      }
      else {
        // If my enemy owns it or if I once owned it
        // -----------------------------------------
        weight = ((p.owner == this.enemy_type) || (p.owner != this.type && p.hasOwned(this))) ? 3 : 1;
        weight = Math.floor((weight * (80 + Math.floor(year / 2))) / d);

        // No more indies after year 150 (15)
        // ----------------------------------
        weight = weight * (year > 150 && p.isIndependent()) ? 0 : 1;
      }

      weight += getRand(5);
      if(weight > 0) {
        moves.push({
          weight: weight,
          planet: p
        });
      }
      moves = moves.sort(function (a,b) { return b.weight - a.weight });
      if(moves.length > 4) {
        moves = moves.slice(0,4);
      }
    }

    // Moves selected, now determine ship pool
    // ---------------------------------------
    var ships = this.home.ships;
    ship_pool = 0;
    
    if(agress < 0) {
      ship_pool = Math.floor(ships / 5);
    }
    else if(agress == 0) {
      ship_pool = (year < 100) ? 
        Math.floor((ships * 3) / 5) :
        Math.floor((ships * 2) / 5);
    }
    else if(agress > 0) {
      ship_pool = (year < 100) ?
        Math.floor((ships * 3) / 4) :
        Math.floor((ships * 1) / 2);
    }

    // Pool selected.  Now create moves.
    // ---------------------------------
    this.app.ge.processMoves(this.home,moves,ship_pool,{
      known_threshold_multiplier: 1.33,
      unknown_thresholds: [
        (15 + Math.floor(year / 2)),
        150
      ]
    });
  }
  else {
    // Home is gone...  select a new one
    // ---------------------------------
    getNewHome(this);
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
    var ship_threshold = 0;
    if(agress < 0) {
      ship_threshold = 6;
    }
    else if(agress == 0) {
      ship_threshold = 15;
    }
    else if(agress > 0) {
      ship_threshold = 10;
    }

    if(p.ships > ship_threshold) {
      // Half the time we dont move ships
      // --------------------------------
      if(getRand(1) == 1) {
        continue;
      }
      var ships_to_move = p.ships - ship_threshold;
      if(ships_to_move > ship_threshold && ships_to_move > 0) {
        this.app.ge.addTransport(p,this.home,ships_to_move);
      }
    }
  }
};
