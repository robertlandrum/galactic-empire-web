window.dbg = function (m) {
  var d = document.getElementById('debug');
  m += "\n";
  var n = document.createTextNode(m);
  d.appendChild(n);
};
window.dbg2 = function (m) {
  var d = document.getElementById('debug');
  d.value = m;
  //m += "\n";
  //var n = document.createTextNode(m);
  //d.appendChild(n);
};

window.findPos = function (obj) {
  var curleft = 0,curtop = 0;
  if (obj.offsetParent) {
    do {
      curleft += obj.offsetLeft;
      curtop += obj.offsetTop;
    } while (obj = obj.offsetParent);
  }
  return {top: curtop, left: curleft};
};

