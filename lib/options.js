var import = require("sibilant/import");
import(require("sibilant/functional"));

var extractOptions = (function(config, args) {
  var args = (args || process.argv.slice(2)),
      defaultLabel = "unlabeled",
      currentLabel = defaultLabel,
      afterBreak = false,
      config = (config || {  }),
      unlabeled = [  ];;
  var label__QUERY = (function(item) {
    return (typeof(item) === "string" && /^-/.test(item));
  });
  ;
  var synonymLookup = (function(item) {
    var configEntry = (config)[item];;
    return (function() { if (typeof(configEntry) === "string") { return synonymLookup(configEntry); } else { return item; } }).call(this);
  });
  ;
  var takesArgs__QUERY = (function(item) {
    return (false !== (config)[labelFor(item)]);
  });
  ;
  defaultLabel = synonymLookup(defaultLabel);
  currentLabel = defaultLabel;;
  var labelFor = (function(item) {
    return synonymLookup(item.replace(/^-+/, ""));
  });
  ;
  var addValue = (function(hash, key, value) {
    var currentValue = (hash)[key];;
    (function() { if (typeof(currentValue) === 'undefined') { currentValue = [  ];; return (hash)[key] = currentValue;; } }).call(this);
    return (function() { if ((true !== value)) { return currentValue.push(value); } }).call(this);
  });
  ;
  var resetLabel = (function() {
    return currentLabel = defaultLabel;;
  });
  ;
  return inject({  }, args, (function(returnHash, item, index) {
    (function() { if (("--" === item)) { return afterBreak = true;; } else { return (function() { if (afterBreak) { return addValue(returnHash, "afterBreak", item); } else { return (function() { if (label__QUERY(item)) { return (function() { currentLabel = labelFor(item);; addValue(returnHash, currentLabel, true); return (function() { if ((!takesArgs__QUERY(item))) { return resetLabel(); } }).call(this); }).call(this); } else { return (function() { addValue(returnHash, currentLabel, item); return resetLabel(); }).call(this); } }).call(this); } }).call(this); } }).call(this);
    return returnHash;
  }));
});

var processOptions = (function(config) {
  var options = extractOptions(config);;
  (function() { if (config) { var handlePair = (function(key, value) {
    var handle = (config)[key];;
    (function() { if (typeof(handle) === "string") { return handlePair(handle, value); } }).call(this);
    return (function() { if (typeof(handle) === 'function') { return handle.apply(undefined, value); } }).call(this);
  });
  ; return Object.keys(options).forEach((function(key) {
    return handlePair(key, (options)[key]);
  })); } }).call(this);
  return options;
});

(module)["exports"] = processOptions;
