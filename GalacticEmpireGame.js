function GalacticEmpireGame (app) {
  this.app = app;
  this.game_over = false;
  this.total_planets = app.PLANETROWS * app.PLANETCOLS;
  this.planets = [];
  this.transports = [];
  this.feeds = [];
  this.enemies = [];
  this.player = new Humans();
  this.current_year = 0;
  this.gamesaved = true;
  this.map_key = undefined;
  this.battle = new Object();

}

GalacticEmpireGame.prototype.initExisting = function () {
  // Always use 8 enemies
  // --------------------
  this.enemies.push(new Gubrus(this.app));
  this.enemies.push(new Czins(this.app));
  this.enemies.push(new Blobs(this.app));
  this.enemies.push(new Bots(this.app));
  this.enemies.push(new Arachs(this.app));
  this.enemies.push(new Mutants(this.app));
  this.enemies.push(new Nukes(this.app));
  this.enemies.push(new Bozos(this.app));

  this.loadMapKey(this.map_key);
};

GalacticEmpireGame.prototype.initNew = function () {
  for (var i = 0; i < this.total_planets; i++) {
    var p = new Planet(i);
    this.planets.push(p); 
  }

  for (var n = 0; n < 99; n++) {
    var r = getRand(this.planets.length - 1);
    this.planets[r].owner = 'INDEPENDENT';
    this.planets[r].industry = getRand(7);
    this.planets[r].ships = this.planets[r].industry;
  }

  // Always use 8 enemies
  // --------------------
  this.enemies.push(new Gubrus(this.app));
  this.enemies.push(new Czins(this.app));
  this.enemies.push(new Blobs(this.app));
  this.enemies.push(new Bots(this.app));
  this.enemies.push(new Arachs(this.app));
  this.enemies.push(new Mutants(this.app));
  this.enemies.push(new Nukes(this.app));
  this.enemies.push(new Bozos(this.app));

  // Create home planets for everyone
  // --------------------------------
  this.setHomePlanet(this.enemies[0],0,0,9,10);
  this.setHomePlanet(this.enemies[1],18,20,27,32);
  this.setHomePlanet(this.enemies[2],18,0,27,10);
  this.setHomePlanet(this.enemies[3],0,20,9,32);
  this.setHomePlanet(this.enemies[4],10,0,17,10);
  this.setHomePlanet(this.enemies[5],0,11,9,19);
  this.setHomePlanet(this.enemies[6],10,20,18,32);
  this.setHomePlanet(this.enemies[7],19,11,27,20);
  this.setHomePlanet(this.player,10,11,17,19);

  this.makeMapKey();
};

GalacticEmpireGame.prototype.getEnemy = function (type) {
  if(type == 'HUMAN') {
    return this.player;
  }

  //console.log('ge: '+this.current_year+': '+type);
  for (var i in this.enemies) {
    if(this.enemies[i].type == type) {
      return this.enemies[i];
    }
  }
  // Should never get here
  // ---------------------
  return this.player;
};


GalacticEmpireGame.prototype.setHomePlanet = function (e,minrow,mincol,maxrow,maxcol) {
  var found = false;
  while(!found) {
    var pcol = getRand((maxcol - mincol)-1) + mincol;
    var prow = getRand((maxrow - minrow)-1) + minrow;
    var id = (prow * window.game.PLANETCOLS) + pcol;

    // If no planet, use for home
    // --------------------------
    if(!this.planets[id].isPlanet()) {
      e.home = this.planets[id];
      e.home.owner = e.type;
      e.home.ships = 100;
      e.home.industry = 10;
      e.home.homeplanet = true;
      if(e.home.isHuman()) {
        e.home.humanpings = 3;
      }
      e.home.setOwned(e.type);
      found = true;
    }
  }
};


GalacticEmpireGame.prototype.processMoves = function (source,moves,ship_pool,opts) {
  var kw_thresh = opts && opts['known_threshold_multiplier'] ? opts['known_threshold_multiplier'] : 1.33;
  var uk = opts && opts['unknown_thresholds'] ? opts['unknown_thresholds'] : [];
  if(typeof uk != 'Array') {
    uk = [uk];
  }

  var min_ships = opts && opts['min_ships'] ? opts['min_ships'] : 0;
  var move_count = moves.length - 1;

  for(var i = move_count; i >= 0; i--) {
    var move = moves[i];
    if(move.planet && move.weight > 0) {
      var ships_avail = Math.floor(ship_pool / (i + 1));
      if(ships_avail <= min_ships) {
        continue;
      }
      
      // See if we can see how many ships there are
      // ------------------------------------------
      if(move.planet.homeplanet || move.planet.hasOwned(source.owner)) {
        // See if we can take them
        // -----------------------
        var x = Math.floor(move.planet.ships * kw_thresh);
        if(ships_avail < x) {
          // Nope.  Not enough ships
          // -----------------------
          continue;
        }
      }
      else {
        var failed = 0;
        for (var u in uk) {
          if(ships_avail < uk[u]) {
            failed++;
          }
        }
        //if(failed > 0)
        //  continue;
        // Safer
        if(failed == uk.length) {
          continue;
        }
      }
      this.addTransport(source,move.planet,ships_avail);
      ship_pool -= ships_avail;
    }
  }
}

GalacticEmpireGame.prototype.calculateTravelTime = function (source,dest) {
  var time = calcTime(source,dest);
  this.current_time = time;
  return time;
};

GalacticEmpireGame.prototype.addTransport = function(source,dest,ships) {
  var timeleft = this.calculateTravelTime(source,dest);

  if(ships > 0) {
    if(source.ships >= ships) {
      if(source.id != dest.id) {
        source.ships -= ships;

        this.transports.push({
          source: source,
          dest: dest,
          owner: source.owner,
          ships: ships,
          ping: ships == 1 ? true : false,
          timeleft: timeleft,
          done: false
        });
      }
    }
  }
};
GalacticEmpireGame.prototype.addFeed = function(source,dest) {
  this.removeFeed(source);
  this.feeds.push({
    source: source,
    dest: dest
  });
};
GalacticEmpireGame.prototype.removeFeed = function(p) {
  var tmp = [];
  for(var i in this.feeds) {
    var f = this.feeds[i];
    if(f.source.id != p.id) {
      tmp.push(f);
    }
  }
  this.feeds = tmp;
};
GalacticEmpireGame.prototype.doBattle = function() {
  // Process Feeds
  // -------------
  for (var f in this.feeds) {
    if(this.feeds[f].source.owner == 'HUMAN') {
      this.addTransport(this.feeds[f].source,this.feeds[f].dest,this.feeds[f].source.ships);
    }
    else {
      this.removeFeed(this.feeds[f].source);
    }
  }

  // Process Enemy Moves
  // -------------------
  for (var e in this.enemies) {
    this.enemies[e].move();
  }

  this.battle.start = this.current_year;
  this.battle.stop = this.current_year + 10;
  this.battle.death_check_done = false;
  
  // Call doYearTick
  // ---------------
  this.doYearTick();
};

GalacticEmpireGame.prototype.checkForDead = function (e) {
  if(e.dead) {
    return true;
  }
  for(var t in this.transports) {
    var trans = this.transports[t];
    if(!trans.done && trans.owner == e.type) {
      return false;
    }
  }
  for (var i in this.planets) {
    var p = this.planets[i];
    if(p.owner == e.type) {
      return false;
    }
  }

  return true;
};

GalacticEmpireGame.prototype.wonGame = function () {
  for (var t in this.transports) {
    var trans = this.transports[t];
    if(!trans.done && trans.owner != 'HUMAN') {
      return false;
    }
  }
  for (var i in this.planets) {
    var p = this.planets[i];
    if(!p.isPlanet() || p.isIndependent()) {
      continue;
    }
    if(p.owner != 'HUMAN') {
      return false;
    }
  }

  return true;
};
GalacticEmpireGame.prototype.lostGame = function () {
  for (var t in this.transports) {
    var trans = this.transports[t];
    if(!trans.done && trans.owner == 'HUMAN') {
      return false;
    }
  }
  for (var i in this.planets) {
    var p = this.planets[i];
    if(p.owner == 'HUMAN') {
      return false;
    }
  }

  return true;
};
GalacticEmpireGame.prototype.doYearTick = function () {
  if(!this.battle.death_check_done && this.current_year > this.battle.start) {
    // update dead enemies
    // -------------------
    //console.log('yt: '+this.current_year+': checking for dead');
    this.battle.enemy_check_index = 0;
    this.doEnemyDeathCheck();
  }
  else {
    // if year not done
    // ----------------
    if((this.current_year + 1) <= this.battle.stop) {
      //console.log('yt: '+this.current_year+': doing year tick');
      // Make sure we do the death check next year
      // -----------------------------------------
      this.battle.death_check_done = false;
      // inc year
      // --------
      this.current_year++;

      // show year
      // ---------
      this.app.redrawTimeDistance();

      // decrement all transports
      // ------------------------
      for (var t in this.transports) {
        if(!this.transports[t].done) {
          this.transports[t].timeleft--;
        }
      }
    
      // call doTransport
      // ------------------
      this.doTransport();
    }
    else {
      //console.log('yt: '+this.current_year+': battle is finished');
      // bump ships counts
      // -----------------
      for (var i in this.planets) {
        var p = this.planets[i];
        if(p.isPlanet()) {
          p.ships += p.industry;
        }
      }

      // end battle
      // ----------
      this.app.battling = false;
    }
  }

};

GalacticEmpireGame.prototype.doEnemyDeathCheck = function () {
  this.app.hideEnemyWindow();

  if(this.enemies[this.battle.enemy_check_index]) {
    var e = this.enemies[this.battle.enemy_check_index];
    this.battle.enemy_check_index++;

    // Enemy...  see if they're already dead.
    // -------------------------------------- 
    if(e.dead) {
      // Go immediately to the next enemy
      // --------------------------------
      //console.log('edc: '+this.current_year+': '+e.type+' is dead, skipping');
      this.doEnemyDeathCheck();
    }
    else {
      if(this.checkForDead(e)) {
        // They are dead.  Show the enemy dead window and delay.
        // -----------------------------------------------------
        //console.log('edc: '+this.current_year+': '+e.type+' has just died');
        e.dead = true;
        this.app.enemyDead(e);
        setTimeout(function () { window.game.ge.doEnemyDeathCheck(); },2500);// * DELAY);
      }
      else {
        // Still alive, go immediately to the next enemy
        // ---------------------------------------------
        //console.log('edc: '+this.current_year+': '+e.type+' is still alive');
        this.doEnemyDeathCheck();
      }
    }
  }
  else {
    // No more enemies to inspect...  finish end of tick sequence.
    // -----------------------------------------------------------
    //console.log('edc: '+this.current_year+': index:'+this.battle.enemy_check_index+' length:'+this.enemies.length);
    
    // check for win
    // -------------
    if(this.wonGame()) {
      this.game_over = true;
      this.app.gameWon();
      return true;
    }
    // check for lose
    // --------------
    if(this.lostGame()) {
      this.game_over = true;
      this.app.gameLost();
      return true;
    }

    this.battle.death_check_done = true;
    this.doYearTick();
  }
};

GalacticEmpireGame.prototype.getNextTransport = function () {
  for (var t in this.transports) {
    if(!this.transports[t].done && this.transports[t].timeleft == 0) {
      return this.transports[t];
    }
  }
  return undefined;
};
GalacticEmpireGame.prototype.doTransport = function () {
  // Hide the bubble
  // ---------------
  this.app.hideBubble();

  // call getNextTransport
  // ---------------------
  var trans = this.getNextTransport();

  if(trans) {
    if(trans.owner == trans.dest.owner) {
      // show fortify window
      // -------------------
      this.app.showBubble(trans);
      trans.dest.ships += trans.ships;
      trans.done = true;

      // call doTransport with setTimeout 60ms
      // -------------------------------------
      setTimeout(function () { window.game.ge.doTransport() },60 * DELAY);
    }
    else {

      if(trans.dest.ships > 0) {
        trans.nofight = false;

        // determine surprise attack
        // -------------------------
        this.battle.surprise = getRand(5) == 0 ? 1 : 0;
        trans.surprise = this.battle.surprise;
        this.battle.trans = trans;

        // show battle window
        // ------------------
        this.app.showBubble(trans);

        // determine fireing order
        // -----------------------
        this.battle.firing_order = this.battle.surprise ? [trans,trans.dest] : [trans.dest,trans];
        this.battle.volley = 0;

        // call doBattleWindow
        // -------------------
        this.doBattleWindow();
      }
      else {
        // They gave up without a fight
        trans.nofight = true;

        // show battle window
        // ------------------
        this.app.showBubble(trans);

        // auto win
        // --------
        trans.dest.owner = trans.owner;
        trans.dest.ships = trans.ships;
        if(trans.owner == 'HUMAN') {
          trans.dest.humanpings = 3;
          trans.dest.lastvisit = this.current_year;
        }
        trans.dest.setOwned(trans.owner);
        
        this.app.attackersWin(trans);
        trans.done = true;

        // call doTransport with setTimeout 120ms
        // --------------------------------------
        setTimeout(function () { window.game.ge.doTransport() },120 * DELAY);
      }
    }
  }
  else {

    // call doYearTick
    // ---------------
    this.doYearTick();
  }
}

GalacticEmpireGame.prototype.doBattleWindow = function () {
  var trans = this.battle.trans;
  if(trans.ships > 0 && trans.dest.ships > 0) {
    var fleet = this.battle.firing_order[this.battle.volley % 2];
    this.battle.fleet = fleet;

    // inc volley
    // ----------
    this.battle.volley++;

    this.battle.opponent = this.battle.firing_order[this.battle.volley % 2];

    // calc firing ships
    // -----------------
    var ships = fleet.ships;
    if(ships > 0) {
      this.battle.ships_to_fire = Math.floor(ships * ((70 + getRand(30)) / 100));
      // call doFireShips
      this.doFireShips();
    }
  }
  else if(this.battle.trans.ships > 0) {
    // attackers win
    // -------------
    trans.dest.owner = trans.owner;
    trans.dest.ships = trans.ships;
    if(trans.owner == 'HUMAN') {
      trans.dest.humanpings = 3;
      trans.dest.lastvisit = this.current_year;
    }
    trans.dest.setOwned(trans.owner);

    this.app.attackersWin(trans);
    trans.done = true;

    // call doTransport with setTimeout 120ms
    // --------------------------------------
    setTimeout(function () { window.game.ge.doTransport(); },120 * DELAY);
  }
  else if(this.battle.trans.dest.ships > 0) {
    // defenders win
    // -------------
    if(trans.owner == 'HUMAN') {
      trans.dest.lastvisit = this.current_year;
      if(trans.dest.humanpings < 3)
        trans.dest.humanpings++;
    }

    this.app.defendersWin(trans);
    trans.done = true;
  
    // call doTransport with setTimeout 120ms
    setTimeout(function () { window.game.ge.doTransport(); },120 * DELAY);
  }
  else {
    // WTF?
  }
}

GalacticEmpireGame.prototype.doFireShips = function () {
  // dec ships to fire
  // -----------------
  this.battle.ships_to_fire--;

  // determine hit
  // -------------
  var hit = getRand(1) == 1 ? true : false;

  if(hit) {
    // dec opponent ships
    // ------------------
    this.battle.opponent.ships--;

    // update attack window
    // --------------------
    this.app.updateBubble(this.battle);
  }

  if(this.battle.opponent.ships > 0) {
    if(this.battle.ships_to_fire > 0) {
      // call doFireShips with setTimeout 4ms
      // ------------------------------------
      if(hit) {
        // Only delay if it was a hit
        // --------------------------
        setTimeout(function () { window.game.ge.doFireShips(); },4 * DELAY);
      }
      else {
        this.doFireShips();
      }
    }
    else {
      // call doBattleWindow with setTimeout 4ms
      // ---------------------------------------
      if(hit) {
        // Only delay if it was a hit
        // --------------------------
        setTimeout(function () { window.game.ge.doBattleWindow(); },4 * DELAY);
      }
      else {
        this.doBattleWindow();
      }
    }
  }
  else {
    // No more oppoent ships
    // call doBattleWindow
    // ---------------------
    this.doBattleWindow();
  }
}

GalacticEmpireGame.prototype.mapKeyLookup = [
  { owner: 'HUMAN', id: '08' },
  { owner: 'BOTS', id: '09' },
  { owner: 'BLOBS', id: '0A' },
  { owner: 'BOZOS', id: '0B' },
  { owner: 'ARACHS', id: '0C' },
  { owner: 'MUTANTS', id: '0D' },
  { owner: 'GUBRU', id: '0E' },
  { owner: 'NUKES', id: '0F' },
  { owner: 'CZIN', id: '10' }
];

GalacticEmpireGame.prototype.getMapKeyOwner = function(v) {
  for(var i in this.mapKeyLookup) {
    var e = this.mapKeyLookup[i];
    if(e.owner == v || e.id == v) {
      return e;
    }
  }
  return undefined;
};

window.pad = function (p,d) {
  while(p.length < d) {
    p = "0"+p;
  }
  return p;
};

GalacticEmpireGame.prototype.makeMapKey = function () {
  var n = 0;
  var c = 0;
  var pstr = '';
  var istr = '';
  var x = '';
  for(var i in this.planets) {
    var p = this.planets[i];
    if(p.isPlanet()) {
      n = n << 1;
      n = n | 1;
      //console.log(i+': '+n);
      c++;

      if(p.isIndependent()) {
        x = p.industry.toString(16);
        if(x.length == 1) {
          x = "0"+x;
        }
        istr += x;
      }
      else {
        var mko = this.getMapKeyOwner(p.owner);
        if(mko == undefined) {
          alert(p.owner+' Not found');
        }
        istr += mko.id;
      }
    }
    else {
      // No planet, shift zeros
      n = n << 1;
      c++;
    }

    if(c > 7) {
      x = n.toString(16);
      if(x.length == 1) {
        x = "0"+x;
      }
      //console.log(i+': Num: '+n+' Hex: '+x+' Bin: '+pad(n.toString(2),8));
      pstr += x;
      n = 0;
      c = 0;
    }
  }
  if(c > 0) {
    x = n.toString(16);
    if(x.length == 1) {
      x = "0"+x;
    }
    pstr += x;
  }
    
  this.map_key = pstr+'^'+istr;
};

GalacticEmpireGame.prototype.loadMapKey = function(key) {
  var pstr = '';
  var istr = '';
  var h;
  var n = 0;
  var o = key.split('^');
  var c = 0;
  var p;
  pstr = o[0];
  istr = o[1];

  while(true) {
    h = pstr.substring(0,2);
    pstr = pstr.substring(2);
    n = parseInt(h,16);

    //console.log(c+': Num: '+n+' Hex: '+h+' Bin: '+pad(n.toString(2),8));
    for (var s = 0; s < 8; s++) {
      var b = n & 128;
      n = n << 1;
      //console.log(c+': Num: '+n+' B: '+b);
      p = new Planet(c);
      if(b) {
        // Planet
        h = istr.substring(0,2);
        istr = istr.substring(2);
        var l = parseInt(h,16);
        if(l < 8) {
          p.owner = 'INDEPENDENT';
          p.industry = l;
          p.ships = l;
        }
        else {
          var mko = this.getMapKeyOwner(h);
          if(mko == undefined) {
            alert(h+' Not found');
          }
          var e = this.getEnemy(mko.owner);

          e.home = p;
          p.owner = e.type;
          p.ships = 100;
          p.industry = 10;
          p.homeplanet = true;
          if(e.type == 'HUMAN') {
            p.humanpings = 3;
          }
          p.setOwned(e.type);
        }
      }
      this.planets.push(p);
      c++;
    }
      
    if(pstr.length == 0) {
      break;
    }
  }
};
// ------------------------------------------------------------------------
// Global Functions for the Game
// ------------------------------------------------------------------------

window.getNPlanets = function (e,pcnt,ships) {
  var count = pcnt || 6;
  var ships_to_send = ships || 15;

  var max = count - 1;
  var moves = [];

  // Iterate over planets
  // --------------------
  for (var i in e.app.ge.planets) {
    var p = e.app.ge.planets[i];
    if(!p.isPlanet()) {
      continue;
    }
    if(p.id == e.home.id) {
      continue;
    }
    var d = calcDSquare(e.home,p);
    var weight = d;

    if(weight > 0) {
      moves.push({
        weight: weight,
        planet: p
      });
      moves = moves.sort(function (a,b) { return a.weight - b.weight });
      if(moves.length > count) {
        moves = moves.splice(0,count);
      }
    }
  }

  for(var m in moves) {
    e.app.ge.addTransport(e.home,moves[m].planet,ships_to_send);
  }
};

window.planetCount = function (e) {
  var count = 0;
  for (var i in e.app.ge.planets) {
    if(e.app.ge.planets[i].owner == e.type) {
      count++;
    }
  }
  return count;
};

window.pickEnemyRandomly = function (e) {
  var eid = getRand(e.app.ge.enemies.length - 1);
  var t = e.app.ge.enemies[eid].type;
  var ot = e.enemy_type || '';
  e.enemy_type = (t == e.type || ot == t) ? 'HUMAN' : t;
  e.enemy = e.app.ge.getEnemy(t);
};

window.pickEnemyClosest = function (e) {
  var weight = 9999;
  var t = '';
  for (var i in e.app.ge.planets) {
    var p = e.app.ge.planets[i];
    if(p.owner == e.type) {
      continue;
    }
    if(p.homeplanet) {
      var d = calcDSquare(e.home,p);
      if(d < weight) {
        weight = d;
        t = p.owner;
      }
    }
  }
  if(t == '') {
    t = 'HUMAN';
  }
  e.enemy_type = t;
  e.enemy = e.app.ge.getEnemy(t);
}

window.calcDSquare = function (source,dest) {
  return (
    (source.col - dest.col) * (source.col - dest.col) +
    (source.row - dest.row) * (source.row - dest.row) 
  );
};

window.calcDistance = function (source,dest) {
  return Math.sqrt(calcDSquare(source,dest));
};

window.calcTime = function (source,dest) {
  return Math.floor(10 * calcDistance(source,dest) * 0.35);
};


window.getRand = function (m) {
  return Math.floor(Math.random() * (m + 1));
};

window.getNewHome = function (e) {
  var max_industry = 0;
  for (var i in e.app.ge.planets) {
    var p = e.app.ge.planets[i];
    if(p.owner == e.type && p.industry > max_industry) {
      max_industry = p.industry;
      e.home = p;
    }
  }
}


