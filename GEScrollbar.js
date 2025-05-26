var mouseTimerDefault = 500;
var mouseTimerMin = 10;
var mouseTimer = mouseTimerDefault;
var mouseDown = false;
var mouseCounter = 0;

function adjMouseTimer () {
  mouseCounter++;
  if(mouseCounter > 1 && mouseTimer > mouseTimerMin) {
    mouseTimer = Math.floor(mouseTimer / 2);
  }
}

function scrollUpMDTimer() {
  if(mouseDown) { 
    scrollMinus(); 
    adjMouseTimer(); 
    setTimeout(scrollUpMDTimer,mouseTimer);
  } 
}

function scrollUpMD() {
  mouseDown = true;
  document.onmouseup = scrollMouseReset;
  setTimeout(scrollUpMDTimer,mouseTimer);
}
function scrollMouseReset() {
  mouseDown = false;
  mouseCounter = 0;
  mouseTimer = mouseTimerDefault;
  document.onmouseup = function () { };
}
function scrollDownMDTimer() {
  if(mouseDown) { 
    scrollPlus(); 
    adjMouseTimer(); 
    setTimeout(scrollDownMDTimer,mouseTimer);
  }
}
function scrollDownMD() {
  mouseDown = true;
  document.onmouseup = scrollMouseReset;
  setTimeout(scrollDownMDTimer,mouseTimer);
}

function scrollMinus() {
  window.sb.moveDown();
  //dbg(window.sb.value);
}
function scrollPlus() {
  window.sb.moveUp();
  //dbg(window.sb.value);
}
function scrollJump(evt) {
  if(window.sb.cancel_click) {
    window.sb.cancel_click = false;
  }
  else {
    var y = evt.pageY - window.sb.channel_pos.top;
    window.sb.jumpScroll(y);
    //dbg(window.sb.value);
  }
}
function scrollMouseDown(evt) {
  window.sb.mouse_down = true;
  document.addEventListener('mouseup',scrollMouseUp,true);
  document.addEventListener('mousemove',scrollMouseMove,true);
  evt.preventDefault();
}
function scrollMouseUp(evt) {
  window.sb.mouse_down = false;
  document.removeEventListener('mouseup',scrollMouseUp,true);
  document.removeEventListener('mousemove',scrollMouseMove,true);
  window.sb.cancel_click = true;
  setTimeout(function () { window.sb.cancel_click = false; },100);
  evt.preventDefault();
}
function scrollMouseMove(evt) {
  if(window.sb.mouse_down) {
    evt.preventDefault();
    var y = evt.pageY - window.sb.channel_pos.top;
    window.sb.moveSlider(y);
    //dbg(window.sb.value);
  }
}

function getIncrements(ships) {
  var inc = 1;
  if(ships > 10) { inc = 10; }
  if(ships >= 200) { inc = 20; }
  if(ships >= 300) { inc = 30; }
  if(ships >= 400) { inc = 40; }
  if(ships >= 500) { inc = 50; }
  if(ships >= 1000) { inc = 100; }
  if(ships >= 2000) { inc = 200; }
  if(ships >= 3000) { inc = 300; }
  if(ships >= 4000) { inc = 400; }
  if(ships >= 5000) { inc = 500; }

  return inc;
}
