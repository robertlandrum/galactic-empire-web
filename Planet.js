function Planet (id) {
  this.id = id;
  this.x = (id % window.game.PLANETCOLS) * window.game.PLANETWIDTH;
  this.y = Math.floor(id / window.game.PLANETCOLS) * window.game.PLANETHEIGHT;
  this.row = Math.floor(id / window.game.PLANETCOLS);
  this.col = (id % window.game.PLANETCOLS);
  this.owner = 'NOPLANET';
  this.lastvisit = 0;
  this.homeplanet = false;
  this.everowned = false;
  this.humanpings = 0;
  this.industry = 0;
  this.ships = 0;
  this.is_feeding = false;
  this.owned = new Object();
};

Planet.prototype.hasOwned = function (e) {
  var type = (typeof e == 'Object') ? e.type : e;
  return (this.owned[type] || false);
};

Planet.prototype.setOwned = function (e) {
  var type = (typeof e == 'Object') ? e.type : e;
  this.owned[type] = true;
  if(type == 'HUMAN') {
    this.everowned = true;
  }
};

Planet.prototype.setLastVisit = function (year) {
  this.lastvisit = year;
};

Planet.prototype.isPlanet = function () {
  return (this.owner != 'NOPLANET');
};

Planet.prototype.isHuman = function () {
  return (this.owner == 'HUMAN');
};
Planet.prototype.isIndependent = function () {
  return (this.owner == 'INDEPENDENT');
};

Planet.prototype.getIcon = function () {
  var icon = '';
  if(this.isPlanet()) {
    if(this.isHuman()) {
      if(this.is_feeding) {
        icon = 'human_feed_planet';
      }
      else if(this.industry == 0) {
        icon = 'human_zero_planet';
      }
      else {
        icon = 'human_planet';
      }
    }
    else {
      icon = this.owner.toLowerCase()+'_planet';
    }
  }
  return icon;
};

Planet.prototype.getImage = function () {
  var img = '';
  if(this.isPlanet()) {
    if(this.isHuman()) {
      img = 'pngs/human_icon_32x32.png';
    }
    else if(this.isIndependent()) {
      img = 'pngs/independent_icon_32x32.png';
    }
    else {
      img = 'pngs/' + this.owner.toLowerCase() + '_icon_32x32.png';
    }
  }
  return img;
};

Planet.prototype.getName = function () {
  var name = '';
  if(this.isPlanet()) {
    if(this.isHuman()) {
      name = 'Human World';
    }
    else if(this.isIndependent()) {
      name = 'Indep. World';
    }
    else {
      name = window.game.ge.getEnemy(this.owner).name + ' World';
    }
  }
  return name;
};

Planet.prototype.canSeeShips = function () {
  return (
    this.owner == 'HUMAN' || 
    this.homeplanet || 
    (this.lastvisit && (window.game.ge.current_year - this.lastvisit) < 11) ||
    this.hasOwned(window.game.ge.player) || 
    (this.humanpings >= 3)
  );
};
Planet.prototype.canSeeIndustry = function () {
  return (
    this.owner == 'HUMAN' || 
    this.homeplanet || 
    this.hasOwned(window.game.ge.player) || 
    (this.humanpings >= 3)
  );
};
