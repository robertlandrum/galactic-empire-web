function GEBubble () {
  this.app = window.game;

  this.big_bubble = document.getElementById('big_bubble');
  this.big_bubble_content = document.getElementById('big_bubble_content');
  this.attacker_text = document.getElementById('attacker_text');
  this.attacker_icon = document.getElementById('attacker_icon');
  this.attacker_ships = document.getElementById('attacker_ships');
  this.defender_text = document.getElementById('defender_text');
  this.defender_icon = document.getElementById('defender_icon');
  this.defender_ships = document.getElementById('defender_ships');
  this.status_text = document.getElementById('status_text');

  this.small_bubble = document.getElementById('little_bubble');
  this.small_bubble_content = document.getElementById('little_bubble_content');
  this.fortify_text = document.getElementById('fortify_text');

  this.active_bubble = undefined;
}

GEBubble.prototype.show = function () {
  if(this.active_bubble) {
    this.active_bubble.style.display = 'block';
  }
};

GEBubble.prototype.hide = function () {
  if(this.active_bubble) {
    this.active_bubble.style.display = 'none';
    this.active_bubble = undefined;
  }
};

GEBubble.prototype.configure = function (trans) {
  // Now determine bubble type
  // -------------------------
  var x = trans.dest.x + 8;  // Center on icon
  var y = trans.dest.y + 8;

  // Bottom Left is default.
  // -----------------------
  var type = "bottom";
  var arrow = "left";

  var bound_width = this.app.canvas_width;
  var bound_height = this.app.canvas_height;

  if(trans.owner == trans.dest.owner) {
    // Fortify
    // -------
    this.active_bubble = this.small_bubble;

    this.fortify_text.innerHTML = trans.ships + ' ships fortify';

    // Smalls are 153x45
    // -----------------
    y -= 45;

    var text_pos_y = 7;
    var text_pos_x = 8;

    if(y < 0) {
      // gotta be top
      type = "top";
      y += 45;
      text_pos_y = 23;
    }
    if(x > bound_width) {
      // gotta be right
      arrow = "right";
      x -= 153;
    }
    // Position the content within the bubble
    // --------------------------------------
    this.small_bubble_content.style.top = text_pos_y+'px';
    this.small_bubble_content.style.left = text_pos_x+'px';

    // Position the bubble within the page
    // -----------------------------------
    this.small_bubble.style.top = (this.app.canvas_position.top + y) + 'px';
    this.small_bubble.style.left = (this.app.canvas_position.left + x) + 'px';

    this.small_bubble.style.backgroundImage = "url('pngs/small_"+type+"_"+arrow+".png')";
    
  }
  else {
    // Attack
    // ------
    this.active_bubble = this.big_bubble;

    this.attacker_ships.innerHTML = trans.ships;
    this.defender_ships.innerHTML = trans.dest.ships;

    var aimg = trans.owner.toLowerCase()+'_icon_32x32.png';
    var dimg = trans.dest.owner.toLowerCase()+'_icon_32x32.png';

    this.attacker_icon.style.backgroundImage = "url('pngs/"+aimg+"')";
    this.defender_icon.style.backgroundImage = "url('pngs/"+dimg+"')";

    this.status_text.innerHTML = trans.surprise ? 'Surprise Attack' : 'Ships Attack';


    // bigs are 203x131
    // ----------------
    y -= 131;

    var text_pos_y = 7;
    var text_pos_x = 8;

    if(y < 0) {
      // gott be top
      type = "top";
      y += 131;
      text_pos_y = 23;
    }

    if(x > bound_width) {
      // gotta be right
      arrow = "right";
      x -= 203;
    }

    // Position the content within the bubble
    // --------------------------------------
    this.big_bubble_content.style.top = text_pos_y+'px';
    this.big_bubble_content.style.left = text_pos_x+'px';

    // Position the bubble within the page
    // -----------------------------------
    this.big_bubble.style.top = (this.app.canvas_position.top + y) + 'px';
    this.big_bubble.style.left = (this.app.canvas_position.left + x) + 'px';

    this.big_bubble.style.backgroundImage = "url('pngs/big_"+type+"_"+arrow+".png')";
  }
};

GEBubble.prototype.update = function (battle) {
  if(this.active_bubble) {
    this.attacker_ships.innerHTML = battle.trans.ships;
    this.defender_ships.innerHTML = battle.trans.dest.ships;
  }
};

GEBubble.prototype.status = function (stat) {
  if(this.active_bubble) {
    this.status_text.innerHTML = stat;
  }
};

GEBubble.prototype.won = function () {
  if(this.active_bubble) {
    this.defender_icon.style.backgroundImage = this.attacker_icon.style.backgroundImage;
  }
};

