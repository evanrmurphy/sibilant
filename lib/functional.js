var functional = exports;
var bulkMap = (function(arr, f) {
  var index = 0,
      groupSize = f.length,
      retArr = [  ];;
  (function() {
    var __returnValue__ = undefined;;
    while ((index < arr.length)) {
      __returnValue__ = (function() {
        retArr.push(f.apply(undefined, arr.slice(index, (index + groupSize))));
        return index += groupSize;
      })();;
    };
    return __returnValue__;
  })();
  return retArr;
});

var inject = (function(start, items, f) {
  var value = start;;
  (function() { if ((items) && (items).constructor.name === "Array") { return items.forEach((function(item, index) {
    return value = f(value, item, index);;
  })); } }).call(this);
  return value;
});

var map = (function(items, f) {
  return inject([  ], items, (function(collector, item, index) {
    collector.push(f(item, index));
    return collector;
  }));
});

var select = (function(items, f) {
  return inject([  ], items, (function(collector, item, index) {
    (function() { if (f(item, index)) { return collector.push(item); } }).call(this);
    return collector;
  }));
});

var detect = (function(items, f) {
  var returnItem = undefined,
      index = 0,
      items = items;;
  return (function() {
    var __returnValue__ = undefined;;
    while ((!((items.length === index) || returnItem))) {
      __returnValue__ = (function() {
        (function() { if (f((items)[index], index)) { return returnItem = (items)[index];; } }).call(this);
        return ((index)++);
      })();;
    };
    return __returnValue__;
  })();
});

var reject = (function(items, f) {
  var args = (function(list, items, f) {
    
  });
  ;
  return select(items, (function() {
    return (!f.apply(undefined, args));
  }));
});

var compact = (function(arr) {
  return select(arr, (function(item) {
    return (!!(item));
  }));
});

[ "inject", "map", "select", "detect", "reject", "compact", "bulkMap" ].forEach((function(exportFunction) {
  return (exports)[exportFunction] = eval(exportFunction);;
}))
