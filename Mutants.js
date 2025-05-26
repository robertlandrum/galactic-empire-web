function Mutants(app) {
  this.type = 'MUTANTS';
  this.name = 'Mutant';
  this.names = 'Mutants';
  this.home = undefined;
  this.dead = false;
  this.planet_count = 0;
  this.enemy = undefined;
  this.enemy_type = undefined;
  this.stage = undefined;
  this.app = app;
};

Mutants.prototype.move = function () {
  if(this.dead) {
    return false;
  }
  var agress = 0;
  var count = 0;
  var year = this.app.ge.current_year;
  var i;
  var p;
  var d;
  var moves = [];
  var weight = 0;
  var d1;
  var ship_pool = 0;

  if(year == 0) {
    pickEnemyRandomly(this);
    this.planet_count = 1;
  }

  count = planetCount(this);

  if(count > this.planet_count) {
    agress = 1;
  }

  if(count < this.planet_count) {
    agress = -1;
  }

  this.planet_count = count;
  
  if(this.enemy.dead) {
    while(this.enemy.dead) {
      pickEnemyRandomly(this);
    }
  }

  // Check to reassign mutant staging planet close to enemy home planet
  // ------------------------------------------------------------------
  if(this.stage) {
    var w = 9999;
    var stage;
    for(i in this.app.ge.planets) {
      p = this.app.ge.planets[i];
      if(!p.isPlanet()) {
        continue;
      }
      if(p.owner == this.type && p.hasOwned(this.enemy)) {
        d = calcDSquare(p,this.enemy.home);
        if(d < w) {
          stage = p;
          w = d;
        }
      }
    }
    if(w < 9999) {
      this.stage = stage;
    }
  }

  // early year game logic
  // ---------------------
  if(year < 90) {
    if(this.home.owner == this.type) {
      // make 4 moves
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
          weight = p.isIndependent() ? 0 : 1;
          weight = Math.floor((weight * 60) / d);
        }
        else if(agress == 0) {
          weight = (
            p.owner == this.enemy_type || 
            (p.owner != this.type && p.hasOwned(this))
          ) ? 2 : 1;
          weight = Math.floor((weight * (120 + Math.floor(year / 2))) / d);
        }
        else if(agress > 0) {
          weight = (p.owner == this.enemy_type) ? 2 : 1;
          weight = Math.floor((weight * (120 + Math.floor(year / 2))) / d);
        }

        weight += getRand(10);

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
      } // end planet loop

      ship_pool = this.home.ships;

      if(agress < 0) {
        ship_pool = Math.floor(ship_pool / 4);
      }
      else if(agress == 0) {
        ship_pool = Math.floor((ship_pool * 3) / 5);
      }
      else if(agress > 0) {
        ship_pool = Math.floor((ship_pool * 3) / 4);
      }

      this.app.ge.processMoves(this.home,moves,ship_pool,{
        known_threshold_multiplier: 1.33,
        unknown_thresholds: [
          (20 + Math.floor(year / 3)),
          150
        ]
      });
    }
    else {
      // No home
      // -------
      getNewHome(this);
    }

    // Send ships home
    // ---------------
    for (i in this.app.ge.planets) {
      p = this.app.ge.planets[i];
      if(p.owner != this.type) {
        continue;
      }
      if(p.ships <= 10) {
        continue;
      }

      this.app.ge.addTransport(p,this.home,(p.ships - 6));
    }

    return true;
  }

  // late game strategy
  // ------------------
  if(this.home.owner == this.type) {
    // Make 4 moves
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

      if(!this.stage && p.owner == this.enemy_type) {
        this.stage = p;
      }

      if(this.enemy.home.id == p.id) {
        if(this.stage &&
          this.stage.owner != this.type &&
          this.home.ships > (2 * this.enemy.home.ships)
        ) {
          ship_pool = Math.floor((this.home.ships * 4) / 5);
          if(ship_pool > 0) {
            this.app.ge.addTransport(this.home,this.enemy.home,ship_pool);
          }
        }
        continue;
      }

      weight = 0;
      d = calcDSquare(this.enemy.home,p);
      d1 = calcDSquare(this.home,p);

      if(d == 0 || d1 == 0) {
        continue;
      }
      if(d == 1)
        d = 2;

      if(agress < 0) {
        weight = (p.owner != this.type && p.hasOwned(this)) ? 1 : 0;
        weight = Math.floor((weight * 100) / d1);
      }
      else if(agress == 0) {
        weight = (p.owner != this.type && p.hasOwned(this)) ? 1 : 0;
        weight = Math.floor((weight * 20) / d1);
        weight *= p.industry == 0 ? 0 : 1;
        weight += ((this.stage && p.id == this.stage.id && p.owner == this.type) ? 1 : 0) * 20;
        weight += Math.floor((((p.owner == this.enemy_type) ? 1 : 0) * 20) / d);

        weight += ((this.stage && p.id == this.stage.id && p.owner == this.type) ? 1 : 0) * 1;
      }
      else if(agress > 0) {
        weight = Math.floor(((p.owner == this.enemy_type ? 1 : 0) * 24) / d);
        weight += ((this.stage && p.id == this.stage.id && p.owner == this.type) ? 1 : 0) * 10;
      }

      weight += getRand(10);

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
    } // end planet loop

    ship_pool = this.home.ships;

    if(agress < 0) {
      ship_pool = Math.floor(ship_pool / 3);
    }
    else if(agress == 0) {
      ship_pool = Math.floor(ship_pool / 2);
    }
    else if(agress > 0) {
      ship_pool = Math.floor((ship_pool * 3) / 5);
    }

    this.app.ge.processMoves(this.home,moves,ship_pool,{
      known_threshold_multiplier: 1.33,
      unknown_thresholds: [
        (20 + Math.floor(year / 3)),
        120
      ]
    });
  }
  else {
    getNewHome(this);
  }

  // late game other planet moves
  // ----------------------------
  for (i in this.app.ge.planets) {
    p = this.app.ge.planets[i];
    if(p.owner != this.type) {
      continue;
    }
    if(p.ships == 0) {
      continue;
    }

    if(this.stage && p.id == this.stage.id && this.stage.owner == this.type) {
      if(this.enemy.home.ships < (2 * p.ships)) {
        ship_pool = this.enemy.home.ships * 2;
        if(ship_pool > 0) {
          this.app.ge.addTransport(p,this.enemy.home,ship_pool);
        }
      }
      weight = 9999;
      var next_planet = undefined;
      for (var k in this.app.ge.planets) {
        var p2 = this.app.ge.planets[k];
        if(p2.owner != this.enemy_type) {
          continue;
        }
        if(p2.id == this.stage.id) {
          continue;
        }

        if(this.stage.ships > (2 * p2.ships)) {
          d = calcDSquare(this.stage,p2);
          if(d < weight) {
            weight = d;
            next_planet = p2;
          }
        }
      }

      if(weight < 9999) {
        ship_pool = Math.floor((next_planet.ships * 3) / 2);
        if(ship_pool == 0) {
          ship_pool = 15 
        }
        if(ship_pool > 0) {
          this.app.ge.addTransport(this.stage,next_planet,ship_pool);
        }
      }
      continue;
    }
    // else

    d = 9999;
    d1 = d;

    if(this.home.owner == this.type) {
      d = calcDSquare(this.home,p);
    }
    if(this.stage && this.stage.owner == this.type) {
      d1 = calcDSquare(this.stage,p);
    }

    if(p.ships > (10 + Math.floor(year / 20))) {
      ship_pool = p.ships - 6;

      var dest = (d1 < d) ? this.stage : this.home;
      this.app.ge.addTransport(p,dest,ship_pool);
    }
  } // end planet loop

};
