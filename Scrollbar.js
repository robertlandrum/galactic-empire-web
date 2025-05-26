function Scrollbar(name,max) {
  this.name = name;
  this.max = max;
  this.up = document.getElementById(name+'_up');
  this.down = document.getElementById(name+'_down');
  this.slider = document.getElementById(name+'_slider');
  this.slider.unselectable = 'on';
  this.slider.style.position = 'relative';
  this.channel = document.getElementById(name+'_channel');
  this.channel.unselectable = 'on';
  this.channel_div = document.getElementById(name+'_channel_div');
  this.channel_div.unselectable = 'on';
  this.channel_div.addEventListener('click',scrollJump,false);
  this.slider.addEventListener('mousedown',scrollMouseDown,false);
  this.channel_pos = findPos(this.channel);
  this.pixel_range = this.channel.height - 16;
  this.value = undefined;
  this.pixel_position = 0;
  this.pixel_step = this.pixel_range / this.max;
  this.increment = 0;
  this.mouse_down = false;
  this.cancel_click = false;
  this.onchange = function () {};

  this.enabled = false;
}

Scrollbar.prototype.setOnChange = function (func) {
  this.onchange = func;
};

Scrollbar.prototype.setRange = function (max) {
  this.max = max;
  this.pixel_step = this.pixel_range / this.max;

};

Scrollbar.prototype.setIncrement = function (inc) {
  this.increment = inc;
};

Scrollbar.prototype.enable = function() {
  this.value = 0;
  this.up.src = "pngs/scrollbar/up-enabled.png";
  this.down.src = "pngs/scrollbar/down-enabled.png";
  this.slider.style.backgroundImage = "url('pngs/scrollbar/slider-enabled.png')";
  this.slider.style.top = '0px';
  this.channel.style.backgroundImage = "url('pngs/scrollbar/channel-enabled.png')";
  this.pixel_position = 0;
  this.enabled = true;

};
Scrollbar.prototype.disable = function() {
  this.value = undefined;
  this.up.src = "pngs/scrollbar/up-disabled.png";
  this.down.src = "pngs/scrollbar/down-disabled.png";
  this.slider.style.backgroundImage = "url('pngs/scrollbar/slider-disabled.png')";
  this.slider.style.top = '0px';
  this.channel.style.backgroundImage = "url('pngs/scrollbar/channel-disabled.png')";
  this.pixel_position = 0;
  this.enabled = false;
};

Scrollbar.prototype.moveUp = function() {
  if(this.enabled) {
    if((this.value + 1) <= this.max) {
      this.value++;
      this.pixel_position += this.pixel_step;
    }
    this.slider.style.top = Math.floor(this.pixel_position) + 'px';
    this.onchange.call(this);
  }
};

Scrollbar.prototype.moveDown = function() {
  if(this.enabled) {
    if(this.value > 0) {
      this.value--;
    }
    if(this.pixel_position > 0) {
      this.pixel_position -= this.pixel_step;
    }
    this.slider.style.top = Math.floor(this.pixel_position) + 'px';
    this.onchange.call(this);
  }
};

Scrollbar.prototype.jumpScroll = function(x) {
  if(this.enabled) {
    // x is the value of the where the mouse clicked
    // ---------------------------------------------
    if(x > this.pixel_position) {
      // We want to add more ships
      // -------------------------
      if((this.value + this.increment) > this.max) {
        this.value = this.max;
        this.pixel_position = this.pixel_range;
      }
      else {
        this.value += this.increment;
        this.pixel_position += (this.pixel_step * this.increment);
      }
    }
    else {
      // We want fewer ships
      // -------------------
      if((this.value - this.increment) < 0) {
        this.value = 0;
        this.pixel_position = 0;
      }
      else {
        this.value -= this.increment;
        this.pixel_position -= (this.pixel_step * this.increment);
      }
    }
    this.slider.style.top = Math.floor(this.pixel_position) + 'px';
    this.onchange.call(this);
  }
};

Scrollbar.prototype.moveSlider = function(x) {
  if(this.enabled) {
    if(x <= this.pixel_range && x >= 0) {
      this.pixel_position = x;
      this.value = Math.floor(this.pixel_position / this.pixel_step);
      if(this.value > this.max) {
        this.value = this.max;
        this.slider.style.top = Math.floor(this.pixel_range) + 'px';
      }
      else {
        this.slider.style.top = Math.floor(this.pixel_position) + 'px';
      }
      this.onchange.call(this);
    }
  }
};
