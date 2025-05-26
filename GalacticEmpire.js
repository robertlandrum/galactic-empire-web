function GalacticEmpire (canid) {
  this.id = canid;
  this.canvas = document.getElementById(canid);
  this.context = this.canvas.getContext('2d');
  this.images = new Object();
  this.autobattle = false;
  this.game_started = false;
  this.sound = true;
  this.PLANETROWS = 27;
  this.PLANETCOLS = 32;
  this.PLANETWIDTH = 16;
  this.PLANETHEIGHT = 16;
  window.DELAY = 10;

  this.canvas_width = this.PLANETCOLS * this.PLANETWIDTH;
  this.canvas_height = this.PLANETROWS * this.PLANETHEIGHT;
  this.next = function () { };
  this.loaded = 0;
  this.source = undefined;
  this.dest = undefined;
  this.planetmap = undefined;
  this.button_pressed = false;
  this.canvas_position = this.findCanvasPosition();

  // Buttons
  // -------
  this.b_dobattle = new GEButton('ge_dobattle');
  this.b_constantfeed = new GEButton('ge_constantfeed');
  this.b_ping = new GEButton('ge_ping');
  this.b_scan = new GEButton('ge_scan');
  this.b_launchall = new GEButton('ge_launchall');
  this.b_launch = new GEButton('ge_launch');

  // Planet Info Section
  // -------------------
  this.pi_from_name = document.getElementById('ge_from_name');
  this.pi_from_icon = document.getElementById('ge_from_icon');
  this.pi_from_ships = document.getElementById('ge_from_ships');
  this.pi_from_industry = document.getElementById('ge_from_industry');

  this.pi_to_name = document.getElementById('ge_to_name');
  this.pi_to_icon = document.getElementById('ge_to_icon');
  this.pi_to_ships = document.getElementById('ge_to_ships');
  this.pi_to_industry = document.getElementById('ge_to_industry');

  this.pi_ship_count = document.getElementById('ge_ship_count');

  // Bubble Div
  // ----------
  this.bubble = new GEBubble('ge_bubble');
  this.bubble.app = this;

  // Scrollbar Onchange
  // ------------------
  this.sb = new Scrollbar('sb');
  window.sb = this.sb;
  this.sb.setOnChange(function () {
    window.game.pi_ship_count.innerHTML = window.game.sb.value + ' Ships';
    window.game.redrawButtons();
  });

  // Time and Distance
  // -----------------
  this.td_travel_time = document.getElementById('gecon_travel_time');
  this.td_current_year = document.getElementById('gecon_current_year');
  
  // Enemy Dead Window
  // -----------------
  this.enemy_dead_win = document.getElementById('enemy_dead_win');
  this.enemy_dead_icon = document.getElementById('enemy_dead_icon');
  this.enemy_dead_text = document.getElementById('enemy_dead_text');

  // Position the Enemy Dead window
  // ------------------------------
  var t = Math.floor((this.canvas_height - 52) / 2);
  var l = Math.floor((this.canvas_width - 280) / 2);
  this.enemy_dead_win.style.top = (this.canvas_position.top + t)+'px';
  this.enemy_dead_win.style.left = (this.canvas_position.left + l)+'px';


  // Graveyard
  // ---------
  this.graveyard = document.getElementById('graveyard');

  this.battle_timeout = undefined;

  this.init();
}

GalacticEmpire.prototype.playSound = function (snd) {
  //console.log('Playing sound: '+snd);
  if(window.sound && this.sound) {
    
    soundManager.play(snd.substring(3,snd.indexOf('.')));
  }
};
GalacticEmpire.prototype.handleLaunch = function () {
  if(this.source && this.dest && this.sb.value > 0) {
    this.ge.addTransport(this.source,this.dest,this.sb.value);
  }

  this.playSound('525launch.wav');

  // Clear the state
  // ---------------
  this.source = undefined;
  this.dest = undefined;

  // Redraw everything
  // -----------------
  this.redrawGalacticEmpire();
};
GalacticEmpire.prototype.handleLaunchAll = function () {
  if(this.source && this.dest) {
    this.ge.addTransport(this.source,this.dest,this.source.ships);
  }

  this.playSound('525launch.wav');

  // Clear the state
  // ---------------
  this.source = undefined;
  this.dest = undefined;

  // Redraw everything
  // -----------------
  this.redrawGalacticEmpire();
};
GalacticEmpire.prototype.handleScan = function () {
  if(this.source && this.dest) {
    this.ge.addTransport(this.source,this.dest,1);
    this.ge.addTransport(this.source,this.dest,1);
    this.ge.addTransport(this.source,this.dest,1);
  }

  this.playSound('142launchone.wav');

  // Clear the state
  // ---------------
  this.source = undefined;
  this.dest = undefined;

  // Redraw everything
  // -----------------
  this.redrawGalacticEmpire();
};

GalacticEmpire.prototype.handlePing = function () {
  if(this.source && this.dest) {
    this.ge.addTransport(this.source,this.dest,1);
  }

  this.playSound('142launchone.wav');

  // Clear the state
  // ---------------
  this.source = undefined;
  this.dest = undefined;

  // Redraw everything
  // -----------------
  this.redrawGalacticEmpire();
};
GalacticEmpire.prototype.handleFeed = function () {
  if(this.source && this.dest) {
    this.ge.addFeed(this.source,this.dest);
  }

  this.playSound('143constantfeed.wav');

  // Clear the state
  // ---------------
  this.source.is_feeding = true;
  this.source = undefined;
  this.dest = undefined;

  // Clear any lines before we draw the PlanetMap
  // --------------------------------------------
  this.redrawGalacticEmpire();

  // Redraw the planet map icons
  // ---------------------------
  this.drawPlanetMap();

  // Redraw everything
  // -----------------
  this.redrawGalacticEmpire();
};

GalacticEmpire.prototype.handleBattle = function () {
  this.source = undefined;
  this.dest = undefined;
  this.battling = true;
  this.game_started = true;

  // Redraw everything
  // -----------------
  this.redrawGalacticEmpire();

  this.playSound('517valkyries.wav');

  // Disable buttons
  // ---------------
  this.b_dobattle.disable();

  // Define the post battle action
  // -----------------------------
  this.next = function () {
    if(!this.ge.game_over) {
      this.b_dobattle.enable();
    }

    this.redrawPlanetMap();

    if(this.autobattle && !this.ge.game_over) {
      this.handleBattle();
    }
  };

  // Start the battle monitor
  // ------------------------
  this.battle_timeout = setTimeout(waitForBattle,100);

  // Do battle
  // ---------
  this.ge.doBattle();
};
function waitForBattle () {
  if(!window.game.battling) {
    window.game.next();
  }
  else {
    window.game.battle_timeout = setTimeout(waitForBattle,100);
  }
}


GalacticEmpire.prototype.redrawGalacticEmpire = function () {
  this.redrawScrollbar();
  this.redrawPlanetMap();
  this.redrawPlanetInfo();
  this.redrawTimeDistance();
  this.redrawButtons();
};

GalacticEmpire.prototype.redrawScrollbar = function () {
  if(this.source && this.source.owner == "HUMAN" && this.source.ships > 0 && this.dest) {
    this.sb.setRange(this.source.ships);
    this.sb.setIncrement(getIncrements(this.source.ships));
    this.sb.enable();
  }
  else {
    this.sb.disable();
  }
};

GalacticEmpire.prototype.redrawPlanetInfo = function () {
  // draw the from data
  // ------------------
  if(this.source) {
    this.pi_from_name.innerHTML = this.source.getName();
    this.pi_from_icon.style.backgroundImage = "url('"+this.source.getImage()+"')";
    var fs = this.source.canSeeShips() ? this.source.ships : '?';
    var fi = this.source.canSeeIndustry() ? this.source.industry : '?';
    this.pi_from_ships.innerHTML = fs+' Ships';
    this.pi_from_industry.innerHTML = fi+' Industry';
  }
  else {
    // clear div
    // ---------
    this.pi_from_name.innerHTML = '';
    this.pi_from_icon.style.backgroundImage = '';
    this.pi_from_icon.style.backgroundColor = '#FFFFFF';
    this.pi_from_ships.innerHTML = '';
    this.pi_from_industry.innerHTML = '';
  }


  // Now draw the to data
  // --------------------
  if(this.dest) {
    this.pi_to_name.innerHTML = this.dest.getName();
    this.pi_to_icon.style.backgroundImage = "url('"+this.dest.getImage()+"')";
    var ts = this.dest.canSeeShips() ? this.dest.ships : '?';
    var ti = this.dest.canSeeIndustry() ? this.dest.industry : '?';
    this.pi_to_ships.innerHTML = ts+' Ships';
    this.pi_to_industry.innerHTML = ti+' Industry';
  }
  else {
    // clear div
    // ---------
    this.pi_to_name.innerHTML = '';
    this.pi_to_icon.style.backgroundImage = '';
    this.pi_to_icon.style.backgroundColor = '#FFFFFF';
    this.pi_to_ships.innerHTML = '';
    this.pi_to_industry.innerHTML = '';
  }

  if(this.sb.enabled) {
    this.pi_ship_count.innerHTML = this.sb.value + ' Ships';
  }
  else {
    this.pi_ship_count.innerHTML = '';
  }
};

GalacticEmpire.prototype.redrawTimeDistance = function () {
  var c = this.ge.current_year;
  var current_year = c ? Math.floor(c/10) + '.' + (c % 10) : '0.0';

  var travel_time = 'N/A';

  if(this.source && this.dest) {
    var t = calcTime(this.source,this.dest);
    if(t > 0) {
      travel_time = Math.floor(t / 10) + '.' + (t % 10);
    }
  }

  this.td_travel_time.innerHTML = travel_time;
  this.td_current_year.innerHTML = current_year;
};

GalacticEmpire.prototype.redrawButtons = function () {
  if(this.source && this.source.owner != 'HUMAN') {
    this.b_launch.disable();
    this.b_launchall.disable();
    this.b_ping.disable();
    this.b_scan.disable();
    this.b_constantfeed.disable();
  }
  else if(this.source && this.dest) {
    if(this.sb.enabled && this.sb.value > 0) {
      this.b_launch.enable();
      this.b_launchall.disable();
      this.b_ping.disable();
      this.b_scan.disable();
      this.b_constantfeed.disable();
    }
    else if(!this.sb.enabled) {
      this.b_launch.disable();
      this.b_launchall.disable();
      this.b_ping.disable();
      this.b_scan.disable();
      this.b_constantfeed.disable();
    }
    else {
      this.b_launch.disable();
      this.b_launchall.enable();
      if(this.source.ships > 0) {
        this.b_ping.enable();
      }
      else {
        this.b_ping.disable();
      }
      if(this.source.ships >= 3) {
        this.b_scan.enable();
      }
      else {
        this.b_scan.disable();
      }
      if(this.dest && this.dest.owner == 'HUMAN') {
        this.b_constantfeed.enable();
      }
      else {
        this.b_constantfeed.disable();
      }
    }
  }
  else {
    // No source or dest everything off
    // --------------------------------
    this.b_launch.disable();
    this.b_launchall.disable();
    this.b_ping.disable();
    this.b_scan.disable();
    this.b_constantfeed.disable();
  }
};

GalacticEmpire.prototype.findCanvasPosition = function () {
  var curleft = 0, curtop = 0;
  var obj = this.canvas;
  if(obj.offsetParent) {
    do {
      curleft += obj.offsetLeft;
      curtop += obj.offsetTop;
    } while(obj = obj.offsetParent);
  }
  return({top: curtop, left: curleft});
};

GalacticEmpire.prototype.pnglist = [
  'arachs_headstone',
  'arachs_icon_32x32',
  'arachs_planet',
  'big_bottom_left',
  'big_bottom_right',
  'big_top_left',
  'big_top_right',
  'blobs_headstone',
  'blobs_icon_32x32',
  'blobs_planet',
  'bots_headstone',
  'bots_icon_32x32',
  'bots_planet',
  'bozos_headstone',
  'bozos_icon_32x32',
  'bozos_planet',
  'czin_headstone',
  'czin_icon_32x32',
  'czin_planet',
  'gubru_headstone',
  'gubru_icon_32x32',
  'gubru_planet',
  'human_feed_planet',
  'human_icon_32x32',
  'human_planet',
  'human_zero_planet',
  'independent_icon_32x32',
  'independent_planet',
  'mutants_headstone',
  'mutants_icon_32x32',
  'mutants_planet',
  'nukes_headstone',
  'nukes_icon_32x32',
  'nukes_planet',
  'small_bottom_left',
  'small_bottom_right',
  'small_top_left',
  'small_top_right',
  'scrollbar/channel-disabled',
  'scrollbar/channel-enabled',
  'scrollbar/down-disabled',
  'scrollbar/down-enabled',
  'scrollbar/up-disabled',
  'scrollbar/up-enabled',
  'scrollbar/slider-disabled',
  'scrollbar/slider-enabled'
];

function waitForLoad () {
  if(window.game.pngsLoaded()) {
    window.game.next();
  }
  else {
    setTimeout(waitForLoad,100);
  }
}

GalacticEmpire.prototype.loadPngs = function () {
  this.loaded = 0;
  for (var i = 0; i < this.pnglist.length; i++) {
    var path = 'pngs/'+this.pnglist[i]+'.png';
    var img = new Image();
    img.onload = function () { window.game.loaded++ };
    img.src = path;
    this.images[this.pnglist[i]] = img;
  }
  this.next = function () { this.continueInit() };
  setTimeout(waitForLoad,100);
};
GalacticEmpire.prototype.pngsLoaded = function () { 
  return (this.loaded >= this.pnglist.length);
};

GalacticEmpire.prototype.init = function () {
  this.loadPngs();
};

GalacticEmpire.prototype.continueInit = function () {
  this.canvas.width = this.canvas_width;
  this.canvas.height = this.canvas_height;
  this.context.fillStyle = "rgb(221,221,221)";
  this.context.fillRect(0,0,this.canvas_width,this.canvas_height);
  this.canvas.onmousedown = function (e) {
    window.game.handleMouseButton(e,'press');
  };
  this.canvas.onmouseup = function (e) {
    window.game.handleMouseButton(e,'release');
  };
  this.canvas.onmousemove = function (e) {
    window.game.handleMouseMove(e);
  };

  //this.context.drawImage(this.images['human_planet'],100,100);
  this.ge = new GalacticEmpireGame(this);
  var qs = window.location.toString().split('?');
  if(qs.length > 1) {
    this.ge.map_key = unescape(qs[1]);
    this.ge.initExisting();
  }
  else {
    this.ge.initNew();
  }
  document.getElementById('maplink').href = qs[0]+"?"+this.ge.map_key;


  // Show the game
  document.getElementById('gegame').style.visibility = 'visible';

  this.drawPlanetMap();
  this.redrawGalacticEmpire()
  
};

GalacticEmpire.prototype.drawPlanetMap = function () {
  for (var i = 0; i < this.ge.planets.length; i++) {
    this.drawPlanet(this.ge.planets[i]);
  }
  this.planetmap = this.context.getImageData(0,0,this.canvas.width,this.canvas.height);
};
GalacticEmpire.prototype.redrawPlanetMap = function () {
  //this.drawPlanetMap();
  this.context.putImageData(this.planetmap,0,0);
  //this.context.drawImage(this.planetmap,0,0,this.canvas.width,this.canvas.height);
  //this.context.clearRect(0,0,this.canvas.width,this.canvas.height);
  //this.context.restore();
  //this.context.save();
};

GalacticEmpire.prototype.drawPlanet = function (planet) {
  if(planet.isPlanet()) {
    var icon = planet.getIcon();
    this.context.save();
    // Clear existing planet
    // ---------------------
    this.context.fillStyle = 'rgb(221,221,221)';
    this.context.fillRect(planet.x,planet.y,this.PLANETWIDTH,this.PLANETHEIGHT);

    //alert(icon);
    //dbg(icon);
    this.context.drawImage(this.images[icon],planet.x,planet.y);
    this.context.restore();
  }
};

GalacticEmpire.prototype.drawPlanetSelect = function (p) {
  this.context.save();
  this.context.strokeStyle = 'rgb(0,0,0)';
  this.context.lineWidth = 1;
  this.context.strokeRect(p.x+0.5,p.y+0.5,this.PLANETWIDTH-1,this.PLANETHEIGHT-1);
  this.context.restore();
};

GalacticEmpire.prototype.getPlanet = function(x,y) {
  var row = Math.floor(y / this.PLANETHEIGHT);
  var col = Math.floor(x / this.PLANETWIDTH);
  var id = (row * this.PLANETCOLS) + col;
  //dbg("row: "+row+" col: "+col+" id: "+id);
  if(this.ge.planets[id].isPlanet()) {
    return this.ge.planets[id];
  }
  return undefined;
};

GalacticEmpire.prototype.handleMouseButton = function (e,type) {
  // Left button only
  // ----------------
  //dbg("Button: "+type);
  if(e.button == 0) {
    var c = this.getMouseCoords(e);
    var x = c.x, y = c.y;
    //dbg("x: "+x+" y: "+y);
    if(type == 'press') {
      this.redrawPlanetMap();
      this.source = undefined;
      this.dest = undefined;
      var p = this.getPlanet(x,y);
      if(p != undefined) {
        this.button_pressed = true;
        this.source = p;
        if(p.is_feeding) {
          p.is_feeding = false;
          this.ge.removeFeed(p);
          this.drawPlanetMap();
          this.redrawPlanetMap();
        }
        this.drawPlanetSelect(p);
      }
      else {
        //dbg("Planet is undefined");
      }
    }
    else if(type == 'release') {
      this.redrawPlanetMap();
      var p = this.getPlanet(x,y);
      this.button_pressed = false;
      if(p != undefined && this.source != undefined && this.source.id != p.id) {
        this.dest = p;
        this.drawPlanetSelect(this.source);
        this.drawPlanetSelect(this.dest);
        this.drawPlanetLine();
      }
      else if(this.source != undefined) {
        this.drawPlanetSelect(this.source);
      }
    }
    this.redrawScrollbar();
    this.redrawPlanetInfo();
    this.redrawButtons();
    this.redrawTimeDistance();
  }
};

GalacticEmpire.prototype.getMouseCoords = function(e) {
  var mx = e.clientX, my = e.clientY;

  mx -= this.canvas_position.left;
  my -= this.canvas_position.top;
  return ({x: mx, y: my});

};

GalacticEmpire.prototype.handleMouseMove = function (e) {
  if(this.button_pressed && this.source != undefined) {
    this.redrawPlanetMap();
    this.drawPlanetSelect(this.source);
    var c = this.getMouseCoords(e);

    this.context.save();
    this.context.strokeStyle = 'rgb(0,0,0)';
    this.context.lineWidth = 1;
    this.context.beginPath();
    this.context.moveTo(this.source.x+8,this.source.y+8);
    this.context.lineTo(c.x,c.y);
    this.context.stroke();
    this.context.restore();
  }
};

GalacticEmpire.prototype.drawPlanetLine = function () {
  this.context.save();
  this.context.strokeStyle = 'rgb(0,0,0)';
  this.context.lineWidth = 1;
  this.context.beginPath();
  this.context.moveTo(this.source.x+8,this.source.y+8);
  this.context.lineTo(this.dest.x+8,this.dest.y+8);
  this.context.stroke();
  this.context.restore();
};


GalacticEmpire.prototype.hideBubble = function () {
  this.bubble.hide();
};

GalacticEmpire.prototype.showBubble = function (t) {
  this.bubble.configure(t);
  this.bubble.show();
};

GalacticEmpire.prototype.updateBubble = function (battle) {
  this.bubble.update(battle);
};

GalacticEmpire.prototype.attackersWin = function (trans) {
  var dest = trans.dest;
  if(trans.owner == 'HUMAN') {
    if(dest.homeplanet) {
      this.playSound('115capturehome.wav');
    }
    else {
      this.playSound('601victorygood.wav');
    }
  }

  if(trans.owner == 'NUKES' && dest.homeplanet) {
    this.playSound('658nukestakehome.wav');
  }

  if(trans.owner == 'BOZOS' && dest.homeplanet) {
    this.playSound('658bozostakehome.wav');
  }


  if(trans.nofight) {
    this.bubble.status('They give up without a fight');
  }
  else {
    this.bubble.status('The Attackers are Victorious');
  }
  this.bubble.won();

  this.drawPlanetMap();
  this.redrawGalacticEmpire();

  this.ge.removeFeed(dest);
  dest.is_feeding = false;
};

GalacticEmpire.prototype.defendersWin = function (trans) {
  if(trans.owner == 'HUMAN') {
    if(!trans.ping) {
      this.playSound('520bummer.wav');
    }
  }

  this.bubble.status('The Defenders Held');
};

GalacticEmpire.prototype.enemyDead = function (e) {
  var eicon = e.type.toLowerCase()+'_icon_32x32.png';
  var death_text = [
    "Croak!",
    "have been wiped out!",
    "bite the dust!",
    "have been eliminated!",
    "choke and die!",
    "are dead meat!"
  ];
  var i = getRand(death_text.length - 1);
  this.enemy_dead_text.innerHTML = e.names + ' ' + death_text[i];
  this.enemy_dead_icon.style.backgroundImage = "url('pngs/"+eicon+"')";
  this.enemy_dead_win.style.display = 'block';

  var grave = e.type.toLowerCase()+'_headstone.png';
  var img = document.createElement('img');
  img.setAttribute('src','pngs/'+grave);
  img.setAttribute('border','0');
  img.setAttribute('height','16');
  img.setAttribute('width','16');
  this.graveyard.appendChild(img);
};

GalacticEmpire.prototype.hideEnemyWindow = function () {
  this.enemy_dead_win.style.display = 'none';
};

GalacticEmpire.prototype.showHighScores = function (scores) {
  $.getJSON('/geweb/scores.pl',{command: 'top10'},function (data) {
    if(data && data.error == 0) {
      window.game.showScores(data);
    }
    else if(data) {
      alert(data.error_message);
    }
    else {
      alert('Failed to fetch scores from Server');
    }
  });
};
GalacticEmpire.prototype.showScores = function (scores) {
  // Remove existing scores
  // ----------------------
  $('#scores tbody tr').each(function () { $(this).remove() });
   
  // Show new scores
  // ---------------
  for (var i in scores.data) {
    var s = scores.data[i];
    var score = Math.floor(s.score / 10) + '.' + (s.score % 10);
    var r = s.rank;
    if(s.map_key != undefined && s.map_key != '') {
      var t = window.location.toString().split('?');
      r = '<a href="'+t[0]+'?'+s.map_key+'" title="Challenge Score">'+r+'</a>';
    }
    $('#scores tbody').append('<tr id="score_'+s.rank+'">' +
      '<td style="text-align: right">'+r+'</td>' +
      '<td>'+s.name+'</td>' +
      '<td>'+score+' years</td>' +
      '<td>'+s.date+'</td>' +
      '</tr>'
    );
  }
  if(scores.rank > 0) {
    $('#score_'+scores.rank+' td').each(function () {
      $(this).addClass('boldtext');
    });
  }

  // Pop the dialog
  // --------------
  $('#score_win').dialog({
    width: 500,
    height: 300,
    resizable: false,
  });
};

GalacticEmpire.prototype.gameWon = function () {
  //alert("You win!"); 
  $.getJSON('/geweb/scores.pl',{command: 'top10'},function (data) {
    if(data && data.error == 0) {
      var is_record = false;
      for (var sidx in data.data) {
        if(window.game.ge.current_year <= data.data[sidx].score) {
          is_record = true;
          break;
        }
      }
      if(is_record) {
        window.game.playSound('513endofgame.wav');
      }
      else {
        window.game.playSound('131winnorecord.wav');
      }
      
      $('#game_won_name_win').dialog({
        modal: true,
        resizable: false,
        open: function () {
          $('#username').focus();
          $('#username').select();
        },
        buttons: {
          'Ok': function () {
            $('#username').removeClass('ui-state-error');
            $('#game_won_name_tips').text('');
            var username = $('#username').val();
            if(username.length >= 3 && !username.match(/[<>%&]/)) {
              $.getJSON('/geweb/scores.pl',{
                command: 'newscore',
                name: username,
                score: window.game.ge.current_year,
                map_key: window.game.ge.map_key
              },function(sdata) {
                $('#game_won_name_win').dialog('close');
                if(sdata && sdata.error == 0) {
                  window.game.showScores(sdata);
                }
                else if(sdata) {
                  alert(sdata.error_message);
                }
                else {
                  alert('Unable to fetch scores from server');
                }

              });
            }
            else {
              // Invalid name
              $('#game_won_name_tips').text("Your name must contain 3 or more characters and may not contain '<', '>', '&', or '%'.").addClass('ui-state-highlight');
              setTimeout(function () {
                $('#game_won_name_tips').removeClass('ui-state-highlight',1500);
              },500);
            }
          },
          'Cancel': function () {
            $('#game_won_name_win').dialog('close');
          }
        }
      });

    }
    else if(data) {
      // Error
      alert(data.error_message);
    }
    else {
      alert('Unable to fetch scores from server');
    }
  });
};
GalacticEmpire.prototype.gameLost = function () {
  $('#game_lost_win').dialog({
    modal: true,
    resizable: false,
    buttons: {
      'Close': function () {
        $('#game_lost_win').dialog('close');
      }
    }
  });
  //alert("You have snatched defeat from the jaws of\nvictory.  The human race has perished.");
};

