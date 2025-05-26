function Bots(app) {
  this.type = 'BOTS';
  this.name = 'Bot';
  this.names = 'Bots';
  this.home = undefined;
  this.dead = false;
  this.planet_count = 0;
  this.enemy = undefined;
  this.enemy_type = undefined;
  this.app = app;
};

Bots.prototype.move = function () {
  if(this.dead) {
    return false;
  }
  var year = this.app.ge.current_year;
  var moves = [];
  var i;
  var p;
  var d;
  var ships_to_move = 0;
  var tp;
  var ship_pool = 0;
  var mcnt = 0;
  var weight = 0;
  var j = 0;
  var move;

  if(year == 0) {
    moves = [];
    
    for (i in this.app.ge.planets) {
      p = this.app.ge.planets[i];
      if(!p.isPlanet()) {
        continue;
      }
      if(p.id == this.home.id) {
        continue;
      }

      d = calcDSquare(p,this.home);
      if(d > 0) {
        moves.push({
          weight: d,
          planet: p
        });
        // Nearest first
        // -------------
        moves = moves.sort(function (a,b) { return a.weight - b.weight });
        if(moves.length > 6) {
          moves = moves.splice(0,6);
        }
      }
    }
    for (var m in moves) {
      this.app.ge.addTransport(this.home,moves[m].planet,15);
    }
    this.enemy_type = 'INDEPENDENT';
    return true;
  }

  if((year % 80) == 0) {
    pickEnemyClosest(this);
  }

  for (i in this.app.ge.planets) {
    p = this.app.ge.planets[i];
    if(!p.isPlanet()) {
      continue;
    }
    if(p.owner != this.type) {
      continue;
    }
    if(p.homeplanet) {
      // do 4 moves
      // ----------
      moves = [];

      for (var o in this.app.ge.planets) {
        tp = this.app.ge.planets[o];
        if(!tp.isPlanet()) {
          continue;
        }
        if(p.id == tp.id) {
          continue;
        }
        if(year > 90 && tp.owner != this.type && tp.owner != this.enemy_type) {
          continue;
        }
        d = calcDSquare(p,tp);

        d = Math.floor(d / 36);
        if(d < 1)
          d = 1;
        if(d > 7)
          d = 7;

        weight = 0;
        if(this.enemy && tp.id == this.enemy.home.id && p.ships > (tp.ships * 2)) {
          weight += 3;
        }
        if(tp.isIndependent() && year < 100) {
          weight += 2;
        }
        if(tp.owner == this.enemy_type)  {
          weight += (d < 2) ? 9 : 4;
        }
        
        if(tp.owner == this.type) {
          if(tp.industry > 3 && d > 1) {
            weight += 7;
          }
          else {
            if(year < 80) {
              weight++;
            }
          }
        }

        // Closer items will have higher weights
        // -------------------------------------
        weight = Math.floor(weight * (36 + Math.floor(year / 5)) / d);
        weight += getRand(15);

        if(weight > 0) {
          moves.push({
            weight: weight,
            planet: tp,
            ships: 0
          });

          moves = moves.sort(function (a,b) { b.weight - a.weight });
          if(moves.length > 4) {
            moves = moves.splice(0,4);
          }
        }
      }

      // Divy up 2/3 of our ships
      // ------------------------
      ship_pool = Math.floor((p.ships * 2) / 3);
      if(ship_pool > 80) {
        var ship_moves = [];
        mcnt = getRand(2) + 2;
        if(mcnt > 3)
          mcnt = 1;
        for (j = 0; j < mcnt; j++) {
          move = moves[j];
          if(move) {
            ships_to_move = 0;
            if(move.planet.owner != this.type) {
              if(move.planet.hasOwned(this) || move.planet.homeplanet) {
                // Make sure we send enough ships to take it
                // -----------------------------------------
                ships_to_move = Math.floor((move.planet.ships * 3) / 2);
              }
              else {
                // Pretend like we can take it
                // ---------------------------
                ships_to_move = 10 + Math.floor(year / 3);
                if(ships_to_move > 150)
                  ships_to_move = 150;
              }
            }
            else {
              // Its one of ours
              // ---------------
              ships_to_move = Math.floor(ship_pool / mcnt);
            }

            if(ships_to_move > 0 && ships_to_move < ship_pool) {
              move.ships = ships_to_move;
              ship_moves[j] = move;
              ship_pool -= ships_to_move;
            }
          }
        }

        for (j = 3; j >= 0; j--) {
          ships_to_move = ship_pool ? Math.floor(ship_pool / (j + 1)) : 0;
          if(moves[j]) {
            tp = moves[j].planet;
            if(ship_moves[j] && ship_moves[j].ships > 0) {
              // Add these stragglers to the pool
              // --------------------------------
              this.app.ge.addTransport(
                p,
                tp,
                (ships_to_move + ship_moves[j].ships)
              );
              ship_pool -= ships_to_move;
            }
          }
        }
      } // end if more than 80 ships
      continue;
    } // end if homeplanet

    if(getRand(2) > 0) {
      continue;
    }

    // Not a home planet
    // -----------------
    moves = [];
    for (i in this.app.ge.planets) {
      tp = this.app.ge.planets[i];
      if(!tp.isPlanet()) {
        continue;
      }
      if(tp.isIndependent() && year > 90) {
        continue;
      }
      if(p.id == tp.id) {
        continue;
      }
      
      d = calcDSquare(p,tp);

      d = Math.floor(d / 25);
      if(d < 1)
        d = 1;
      if(d > 5)
        d = 6;

      weight = 0;
      if(this.enemy && tp.id == this.enemy.home.id && tp.ships < (2 * p.ships)) {
        weight += 2;
      }

      if(tp.isIndependent()) {
        weight++;
      }

      if(tp.owner == this.enemy_type) {
        weight += 5;
      }
      
      if(tp.id != this.home.id && tp.owner == this.type && tp.industry > p.industry) {
        weight += (tp.industry - p.industry);
      }

      if(tp.id == this.home.id) {
        if(tp.owner != this.type) {
          weight += 10;
        }
        else if(year > 90 && d < 2) {
          weight += 3;
        }
        else {
          weight++;
        }
      }

      // Closer planets have heigher weights
      // -----------------------------------
      weight = Math.floor((weight * 25) / d);
      weight += getRand(10);

      if(weight > 0) {
        moves.push({
          weight: weight,
          planet: tp,
          ships: 0
        });

        moves = moves.sort(function (a,b) { b.weight - a.weight });
        if(moves.length > 4) {
          moves = moves.splice(0,4);
        }
      }
    } // end planet loop

    // Determine ships to send
    // -----------------------
    ship_pool = p.industry ? Math.floor((p.ships * 3) / 4) : p.ships;

    if(ship_pool > Math.floor(year  / 4) || ship_pool > 30) {
      mcnt = getRand(3) + 1;
      if(mcnt > 3)
        mcnt = 1;

      for(j = 0; j < mcnt; j++) {
        move = moves[j];
        if(!move) {
          continue;
        }
        ships_to_move = 0;
        if(move.planet.owner != this.type) {
          if(move.planet.hasOwned(this) || move.planet.homeplanet) {
            ships_to_move = Math.floor((move.planet.ships * 3) / 2);
          }
          else {
            ships_to_move = 10 + Math.floor(year / 3);
            if(ships_to_move > 80)
              ships_to_move = 80;
          }
        }
        else {
          ships_to_move = Math.floor(ship_pool / mcnt);
        }

        if(ships_to_move > 0 && ships_to_move < ship_pool) {
          move.ships = ships_to_move;
          ship_pool -= ships_to_move;
        }
      }
      for(j = mcnt; j >= mcnt; j--) {
        ships_to_move = Math.floor(ship_pool / (j + 1));
        move = moves[j];
        if(!move) {
          continue;
        }
        if(move.ships == 0) {
          continue;
        }
        ship_pool -= ships_to_move;
        ships_to_move += move.ships;
        this.app.ge.addTransport(p,move.planet,ships_to_move);
      }
    }
  }
};
