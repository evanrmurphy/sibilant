var functional = exports;
var bulkMap = (function(arr, f) {
  // arr:required f:required
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
  // start:required items:required f:required
  var value = start;;
  (function() {
    if ((items) && (items).constructor.name === "Array") {
      return items.forEach((function(item, index) {
        // item:required index:required
        return value = f(value, item, index);;
      }));
    };
  })();
  return value;
});

var map = (function(items, f) {
  // items:required f:required
  return inject([  ], items, (function(collector, item, index) {
    // collector:required item:required index:required
    collector.push(f(item, index));
    return collector;
  }));
});

var select = (function(items, f) {
  // items:required f:required
  return inject([  ], items, (function(collector, item, index) {
    // collector:required item:required index:required
    (function() {
      if (f(item, index)) {
        return collector.push(item);
      };
    })();
    return collector;
  }));
});

var detect = (function(items, f) {
  // items:required f:required
  var returnItem = undefined,
      index = 0,
      items = items;;
  return (function() {
    var __returnValue__ = undefined;;
    while ((!((items.length === index) || returnItem))) {
      __returnValue__ = (function() {
        (function() {
          if (f((items)[index], index)) {
            return returnItem = (items)[index];;
          };
        })();
        return ((index)++);
      })();;
    };
    return __returnValue__;
  })();
});

var reject = (function(items, f) {
  // items:required f:required
  var args = (function(list, items, f) {
    // list:required items:required f:required
  });
  ;
  return select(items, (function() {
    return (!f.apply(undefined, args));
  }));
});

var compact = (function(arr) {
  // arr:required
  return select(arr, (function(item) {
    // item:required
    return (!!(item));
  }));
});

[ "inject", "map", "select", "detect", "reject", "compact", "bulkMap" ].forEach((function(exportFunction) {
  // exportFunction:required
  return (exports)[exportFunction] = eval(exportFunction);;
}))
