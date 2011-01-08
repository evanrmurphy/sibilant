module.exports = (function(module) {
  return (function() {
    for (var fName in module) (function() {
      return (function() { if (module.hasOwnProperty(fName)) { return (global)[fName] = (module)[fName];; } }).call(this);
    })();
  })();;
});

