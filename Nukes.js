function Nukes(app) {
  this.type = 'NUKES';
  this.name = 'Nuke';
  this.names = 'Nukes';
  this.home = undefined;
  this.dead = false;
  this.planet_count = 0;
  this.enemy = undefined;
  this.enemy_type = undefined;
  this.stage = undefined;
  this.next = undefined;
  this.ndiv = 0;
  this.bored = 0;
  this.app = app;
};

Nukes.prototype.move = function () {
  if(this.dead) {
    return false;
  }
  var agress = 0;
  var ccount = 0;
  var year = this.app.ge.current_year;
  var i;
  var p;
  var weight = 0;
  var d = 0;


  if(year == 0) {
    pickEnemyRandomly(this);

    moves = [];

    for (i in this.app.ge.planets) {
      p = this.app.ge.planets[i];
      if(!p.isPlanet()) {
        continue;
      }
      if(p.owner == this.type) {
        this.stage = p;
        this.next = p;
        continue;
      }
      if(p.id == this.home.id) {
        continue;
      }
      d = calcDSquare(p,this.home);

      if(d < 9999) {
        moves.push({
          weight: d,
          planet: p
        });
        moves = moves.sort(function (a,b) { return a.weight - b.weight });
        if(moves.length > 6) {
          moves = moves.splice(0,6);
        }
      }
    }
    for (var m in moves) {
      this.app.ge.addTransport(this.home,moves[m].planet,15);
    }
    this.ndiv = 5;
    return false;
  }

  // Enemy dead?
  // -----------
  if(this.enemy.dead) {
    while(this.enemy.dead) {
      pickEnemyRandomly(this);
    }
  }

  if(this.next.owner == this.type) {
    this.stage = this.next;
    this.bored = 2;
  }
  if(this.enemy.home.owner == this.type) {
    var et = this.enemy_type;
    var oe = this.enemy;
    this.home = this.enemy.home;
    this.stage = this.home;
    this.next = this.home;
    var found = false;
    pickEnemyRandomly(this);
    for (i in this.app.ge.planets) {
      p = this.app.ge.planets[i];
      if(p.homeplanet && p.owner == this.enemy_type) {
        this.ndiv = 4;
        found = true;
      }
    }

    if(!found) {
      this.enemy_type = et;
      this.enemy = oe;
      return false;
    }
  }

  if(this.stage.id == this.next.id) {
    // determine next planet
    // ---------------------
    if(this.ndiv > 0) {
      var x = Math.floor(((this.stage.col - this.enemy.home.col) * (this.ndiv - 1)) / this.ndiv);
      x += this.enemy.home.col;

      var y = Math.floor(((this.stage.row - this.enemy.home.row) * (this.ndiv - 1)) / this.ndiv);
      y += this.enemy.home.row;
      this.ndiv--;

      weight = 9999;
      for (i in this.app.ge.planets) {
        p = this.app.ge.planets[i];
        if(!p.isPlanet()) {
          continue;
        }
        if(p.owner == this.type) {
          continue;
        }

        d = ((p.row - y) * (p.row - y)) + ((p.col - x) * (p.col - x));
        if(d < weight) {
          weight = d;
          this.next = p;
        }
      }
    }
    else {
      this.next = this.enemy.home;
    }

    var t = calcTime(this.next,this.stage);
    this.wait = Math.floor((t + 10) / 10);
  }

  // if we lose staging revert to home
  // ---------------------------------
  if(this.stage.owner != this.type) {
    this.stage = this.home;
  }


  // other year send to staging planet
  // ---------------------------------
  for (i in this.app.ge.planets) {
    p = this.app.ge.planets[i];
    if(p.owner != this.type) {
      continue;
    }
    if(p.id != this.stage.id) {
      // not our staging planet
      // ----------------------
      ship_pool = p.ships;
      if(p.id == this.home.id) {
        ship_pool -= 50 + Math.floor(year / 10);
      }
      else {
        ship_pool -= 10 + Math.floor(year / 20);
      }
      if(ship_pool > (10 + getRand(25))) {
        this.app.ge.addTransport(p,this.stage,ship_pool);
      }
    }
    else {
      // staging planet logic
      // --------------------
      if(this.wait > 0) {
        this.wait--;
        this.app.ge.addTransport(this.stage,this.next,1);
      }
      else {
        if(this.next.ships > Math.floor((6 * year) / 10)) {
          // too many ships pick new next planet
          // -----------------------------------
          this.next = this.stage;
          continue;
        }
        
        if(Math.floor((this.next.ships * 5) / 3) < this.stage.ships) {
          // We can take them
          // ----------------
          this.app.ge.addTransport(this.stage,this.next,this.stage.ships);
        }
        else {
          // Not enough ships
          // ----------------
          this.bored--;
          if(this.bored < 0) {
            weight = 9999;
            var move = { weight: weight, planet: undefined };
            for (var k in this.app.ge.planets) {
              var p2 = this.app.ge.planets[k];
              if(p2.owner == this.enemy_type) {
                if(p2.id == this.stage.id) {
                  continue;
                }
                d = calcDSquare(this.stage,p2);
                if(d < weight) {
                  weight = d;
                  move.weight = weight;
                  move.planet = p2;
                }
              }
            }
            if(weight < 9999 && move.planet) {
              this.bored = 1;
              this.next = move.planet;
              this.wait = Math.floor((move.weight + 10) / 10);
            }
          } // end if bored
        } // end if not enough ships
      } // end if waiting
    } // end if staging
  } // end planet loop
      
};
