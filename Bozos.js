function Bozos(app) {
  this.type = 'BOZOS';
  this.name = 'Bozo';
  this.names = 'Bozos';
  this.home = undefined;
  this.dead = false;
  this.planet_count = 0;
  this.enemy = undefined;
  this.enemy_type = undefined;
  this.stage = undefined;
  this.next = undefined;
  this.wait = 9999;
  this.search = [];
  this.app = app;
};


Bozos.prototype.move = function () {
  if(this.dead) {
    return false;
  }

  var year = this.app.ge.current_year;
  var p;
  var i;
  var d;
  var w = 0;
  var weight = 0;



  if(year == 0) {
    this.stage = this.home;
    this.wait = 9999;

    getNPlanets(this,6,15);
    return false;
  }

  if(this.next && this.next.owner == this.type) {
    this.stage = this.next;
    this.next = undefined;
    this.wait = 9999;
  }

  // We need to check to make sure stage is ours or else
  // we end up stealing ships ( in old version web did,
  // in new version we just launch other peoples ships)
  // ---------------------------------------------------
  if(this.stage && this.stage.owner != this.type) {
    // Bummer.  Our stage was lost.
    // We need to pick a new stage
    // Lets pick the planet with the most ships
    // ----------------------------------------
    w = 0;
    for (i in this.app.ge.planets) {
      p = this.app.ge.planets[i];
      if(p.owner == this.type && p.ships > w) {
        this.stage = p;
        w = p.ships;
      }
    }
  }

  // Its possible we have no planets so make no moves until we do
  // ------------------------------------------------------------
  if(!(this.stage && this.stage.owner == this.type)) {
    return false;
  }

  // Late game strategy
  // ------------------
  var enemy = undefined;
  if(year > 180) {
    d = 0;
    weight = 0;
    
    // Alien with most planets is enemy
    // --------------------------------
    for (var ei in this.app.ge.enemies) {
      var e = this.app.ge.enemies[ei];
      for (var pi in this.app.ge.planets) {
        p = this.app.ge.planets[pi];
        if(!p.isPlanet()) {
          continue;
        }
        if(p.hasOwned(this) && p.owner == e.type) {
          weight++;
        }
      }
      if(weight > d) {
        enemy = e.type;
        d = weight;
      }
    }

    if(d > 0) {
      for (i in this.app.ge.planets) {
        if(!p.isPlanet()) {
          continue;
        }
        if(p.owner == enemy && p.homeplanet && p.stage.ships > (2 * p.ships)) {
          this.app.ge.addTransport(this.stage,p,this.stage.ships);
          break;
        }
      }
    }

    if(!enemy) {
      enemy = "INDEPENDENT";
    }
  }
  else {
    enemy = "INDEPENDENT";
  }

  if(this.wait == 9999 && !this.next && this.stage.ships >= 5) {
    var moves = [];
    for (i in this.app.ge.planets) {
      p = this.app.ge.planets[i];
      if(!p.isPlanet()) {
        continue;
      }
      if(p.owner == this.type) {
        continue;
      }
      if(p.id == this.stage.id) {
        continue;
      }

      d = calcDSquare(this.stage,p);

      if(p.owner != enemy) {
        d *= 10;
      }

      if(d > 0) {
        moves.push({
          weight: d,
          planet: p
        });

        moves = moves.sort(function (a,b) { return a.weight - b.weight });
        if(moves.length > 5) {
          moves = moves.splice(0,5);
        }
      }
    }

    weight = 0;
    for (var m in moves) {
      this.search[m] = moves[m].planet;
      var time = calcTime(this.stage,moves[m].planet);
      if(time > weight) {
        weight = time;
      }
      if(this.stage.ships) {
        this.app.ge.addTransport(
          this.stage,
          moves[m].planet,
          1
        );
      }
    }
    this.wait = Math.floor((weight + 10) / 10);
  }

  // Home planet logic
  // -----------------
  if(this.stage.id != this.home.id) {
    if(this.home.owner == this.type) {
      var ship_pool = this.home.ships - (25 + Math.floor(year / 20));
      if(ship_pool > 15) {
        this.app.ge.addTransport(this.home,this.stage,ship_pool);
      }
    }
  }

  // Staging planet logic
  // --------------------
  if(this.wait != 9999) {
    this.wait--;
  }

  if(this.wait <= 0) {
    var move = undefined;
    var j = 0;
    var found = false;
    w = 9999;

    // For each of our pinged hosts, see if we own it and if not 
    // see if we can take it
    // ---------------------------------------------------------
    for (i in this.search) {
      p = this.search[i];
      if(p.owner != this.type) {
        if(p.ships > j && (p.ships < Math.floor((2 * this.stage.ships) / 3))) {
          move = p;
          j = p.ships;
          found = true;
        }
      }
    }

    // If we found none we didnt own or couldnt take, find the one with
    // the fewest ships
    // ----------------------------------------------------------------
    if(!found) {
      for (i in this.search) {
        p = this.search[i];
        if(p.owner != this.type && p.ships < w) {
          w = p.ships;
          move = p;
          found = true;
        }
      }
    }

    // If we still havent found a target, move all staging ships to the 
    // nearest of the pinged planets
    // ----------------------------------------------------------------
    if(!found) {
      if(this.stage.ships > 0) {
        this.next = this.search[0];
        if(this.next) {
          this.app.ge.addTransport(this.stage,this.next,this.stage.ships);
        }
      }
    }
    else {
      if(move.owner != this.type && this.stage.ships > Math.floor((3 * move.ships) / 2)) {
        this.next = move;
        if(this.stage.ships > 0) {
          this.app.ge.addTransport(this.stage,this.next,this.stage.ships);
        }
      }
    }

    // Every 5th year check to nuke home planet
    // ----------------------------------------
    if((year % 50) == 0) {
      for (i in this.app.ge.planets) {
        p = this.app.ge.planets[i];
        if(!p.isPlanet()) {
          continue;
        }
        if(p.homeplanet && p.owner != this.type && this.stage.ships > (2 * p.ships)) {
          this.app.ge.addTransport(this.stage,p,this.stage.ships);
        }
      }
    }
  }

  // Other planets logic
  // -------------------
  for (i in this.app.ge.planets) {
    p = this.app.ge.planets[i];
    if(!p.isPlanet()) {
      continue;
    }
    if(p.owner != this.type) {
      continue;
    }
    if(this.stage.id == p.id) {
      continue;
    }
    if(this.home.id == p.id) {
      continue;
    }
    if(p.ships > 10) {
      this.app.ge.addTransport(p,this.stage,p.ships);
    }
  }
};
