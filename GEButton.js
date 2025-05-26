function GEButton (name) {
  this.name = name;
  this.element = document.getElementById(name);
}

GEButton.prototype.enable = function () {
  this.element.disabled = false;
};

GEButton.prototype.disable = function () {
  this.element.disabled = true;
};
