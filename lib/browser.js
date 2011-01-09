(function() {
  var sibilant = [  ];;
  var error = (function(str) {
    throw new Error ((new Error(str)));
  });
  ;
  var inspect = (function(item) {
    return (function() { if (item.toSource) { return item.toSource(); } else { return item.toString(); } }).call(this);
  });
  ;
  (window)["sibilant"] = sibilant;;
  var exports = {  };;
  var functional = exports;
  var bulkMap = (function(arr, f) {
    var index = 0,
        groupSize = f.length,
        retArr = [  ];;
    (function() {
      var __returnValue__ = undefined;;
      while ((index < arr.length)) { __returnValue__ = (function() {
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
      while ((!((items.length === index) || returnItem))) { __returnValue__ = (function() {
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
  ;
  sibilant.tokens = {  };
  (sibilant.tokens)["regex"] = "(\\/(\\\\\\\/|[^\\/\\n])+\\/[glim]*)";
  (sibilant.tokens)["comment"] = "(;.*)";
  (sibilant.tokens)["string"] = "(\"(([^\"]|(\\\\\"))*[^\\\\])?\")";
  (sibilant.tokens)["number"] = "(-?[0-9.]+)";
  (sibilant.tokens)["literal"] = "([*.$a-zA-Z-=+?:][*.a-zA-Z0-9-=+?:]*(!)?)";
  (sibilant.tokens)["special"] = "([&']?)";
  (sibilant.tokens)["otherChar"] = "([><=!\\+\\/\\*-]+)";
  (sibilant.tokens)["openParen"] = "(\\()";
  (sibilant.tokens)["specialOpenParen"] = "('?\\()";
  (sibilant.tokens)["closeParen"] = "(\\))";
  (sibilant.tokens)["alternativeParens"] = "\\{|\\[|\\}|\\]";
  (sibilant.tokens)["specialLiteral"] = (sibilant.tokens.special + sibilant.tokens.literal);
  sibilant.tokenPrecedence = [ "regex", "comment", "string", "number", "specialLiteral", "otherChar", "specialOpenParen", "closeParen", "alternativeParens" ];
  var tokenize = sibilant.tokenize = (function(string) {
    var tokens = [  ],
        parseStack = [ tokens ],
        specials = [  ];;
    var acceptToken = (function(token) {
      return (parseStack)[0].push(token);
    });
    ;
    var increaseNesting = (function() {
      var newArr = [  ];;
      acceptToken(newArr);
      return parseStack.unshift(newArr);
    });
    ;
    var decreaseNesting = (function() {
      specials.shift();
      parseStack.shift();
      return (function() { if ((parseStack.length === 0)) { throw new Error (("unbalanced parens:\n" + inspect(parseStack))); } else { return undefined; } }).call(this);
    });
    ;
    var handleToken = (function(token) {
      var special = (token)[0],
          token = token;;
      ((special === "'") ? (function() { token = token.slice(1);; increaseNesting(); return acceptToken("quote"); }).call(this) : (function() {return special = false;}).call(this));
      specials.unshift((!!(special)));
      ((token === "(") ? increaseNesting() : (((token === "]") || (token === "}") || (token === ")")) ? decreaseNesting() : ((token === "{") ? (function() { increaseNesting(); return acceptToken("hash"); }).call(this) : ((token === "[") ? (function() { increaseNesting(); return acceptToken("list"); }).call(this) : (token.match((new RegExp(("^" + sibilant.tokens.number + "$"), undefined))) ? acceptToken(parseFloat(token)) : acceptToken(token))))));
      return (((token !== "(") && specials.shift()) ? decreaseNesting() : undefined);
    });
    ;
    var orderedRegexen = map(sibilant.tokenPrecedence, (function(x) {
      return (sibilant.tokens)[x];
    })),
        masterRegex = (new RegExp((orderedRegexen).join("|"), "g"));;
    string.match(masterRegex)
    .forEach(handleToken);
    ((parseStack.length > 1) ? error("unexpected EOF, probably missing a )\n", inspect((parseStack)[0])) : undefined);
    return tokens;
  });;
  ;
  
  var indent = (function(args) {
    var args = Array.prototype.slice.call(arguments, 0);
    
    return (compact(args).join("\n")
    .replace(/^/, "\n")
    .replace(/\n/g, "\n  ") + "\n");
  });
  
  var constructHash = (function(arrayOfArrays) {
    return inject({  }, arrayOfArrays, (function(object, item) {
      (object)[(item)[0]] = (object)[(item)[1]];;
      return object;
    }));
  });
  
  var macros = {  };
  sibilant.macros = macros;
  macros.return = (function(token) {
    var defaultReturn = ("return " + translate(token));;
    return ((token) && (token).constructor.name === "Array" ? (function() {
      switch((token)[0]) {
      case "return":
      case "throw":
      case "do":
        return translate(token);
      
      case "delete":
        var deleteMacro = (macros)["delete"];; return ((token.length < 3) ? defaultReturn : (deleteMacro.apply(undefined, token.slice(1, -1)) + "\nreturn " + deleteMacro((token.slice(-1))[0])));
      
      case "=":
        return ((token.length < 4) ? defaultReturn : ((macros)["="].apply(undefined, token.slice(1, (token.length - 2))) + "\nreturn " + (macros)["="].apply(undefined, token.slice(-2))));
      
      case "set":
        return ((token.length < 5) ? defaultReturn : (function() { var obj = (token)[1],
            nonReturnPart = token.slice(2, (token.length - 2)),
            returnPart = token.slice(-2);; nonReturnPart.unshift(obj); returnPart.unshift(obj); return (macros.set.apply(undefined, nonReturnPart) + "\nreturn " + macros.set.apply(undefined, returnPart)); }).call(this));
      
      default:
        return defaultReturn;
      }
    })() : defaultReturn);
  });
  macros.statement = (function(args) {
    var args = Array.prototype.slice.call(arguments, 0);
    
    return (macros.call.apply(undefined, args) + ";\n");
  });
  
  macros.do = (function(body) {
    var body = Array.prototype.slice.call(arguments, 0);
    
    var lastIndex = Math.max(0, (body.length - 1));;
    (body)[lastIndex] = [ "return", (body)[lastIndex] ];;
    return (map(body, (function(arg) {
      return (translate(arg) + ";");
    }))).join(" ");
  });
  
  macros.call = (function(fName, args) {
    var args = Array.prototype.slice.call(arguments, 1);
    
    return (translate(fName) + "(" + (map(args, translate)).join(", ") + ")");
  });
  
  macros.def = (function(fName, argsAndBody) {
    var argsAndBody = Array.prototype.slice.call(arguments, 1);
    
    var fNameTr = translate(fName),
        start = (/\./(fNameTr) ? "" : "var ");;
    return (start + fNameTr + " = " + macros.fn.apply(undefined, argsAndBody) + ";\n");
  });
  
  macros.mac = (function(name, argsAndBody) {
    var argsAndBody = Array.prototype.slice.call(arguments, 1);
    
    var js = macros.fn.apply(undefined, argsAndBody),
        name = translate(name);;
    (function() { try { return (macros)[name] = eval(js);; } catch (e) { return error(("error in parsing macro " + name + ":\n" + indent(js))); } }).call(this);
    return undefined;
  });
  
  macros.concat = (function(args) {
    var args = Array.prototype.slice.call(arguments, 0);
    
    return ("(" + (map(args, translate)).join(" + ") + ")");
  });
  
  (macros)["__PLUS"] = (function(args) {
    var args = Array.prototype.slice.call(arguments, 0);
    
    return ("(" + (map(args, translate)).join(" + ") + ")");
  });
  var transformArgs = (function(arglist) {
    var last = undefined,
        args = [  ];;
    arglist.forEach((function(arg) {
      return (((arg)[0] === "&") ? (function() {return last = arg.slice(1);}).call(this) : (function() { args.push([ (last || "required"), arg ]); return last = null;; }).call(this));
    }));
    (last ? error(("unexpected argument modifier: " + last)) : undefined);
    return args;
  });
  
  macros.reverse = (function(arr) {
    var reversed = [  ];;
    arr.forEach((function(item) {
      return reversed.unshift(item);
    }));
    return reversed;
  });
  
  var reverse = macros.reverse;
  var buildArgsString = (function(args, rest) {
    var argsString = "";;
    return (typeof(rest) !== 'undefined' ? (argsString + "var " + translate((rest)[1]) + " = Array.prototype.slice.call(arguments, " + args.length + ");\n") : argsString);
  });
  
  macros.fn = (function(arglist, body) {
    var body = Array.prototype.slice.call(arguments, 1);
    
    var args = transformArgs(arglist),
        rest = (select(args, (function(arg) {
      return ("rest" === (arg)[0]);
    })))[0],
        docString = undefined;;
    (body)[(body.length - 1)] = [ "return", (body)[(body.length - 1)] ];;
    (((typeof((body)[0]) === "string") && (body)[0].match(/^".*"$/)) ? (function() {return docString = ("/* " + eval(body.shift()) + " */\n");}).call(this) : undefined);
    var noRestArgs = (rest ? args.slice(0, -1) : args),
        argsString = buildArgsString(noRestArgs, rest);;
    return ("(function(" + (map(args, (function(arg) {
      return translate((arg)[1]);
    }))).join(", ") + ") {" + indent(docString, argsString, (map(body, (function(stmt) {
      return (translate(stmt) + ";");
    }))).join("\n")) + "})");
  });
  
  macros.quote = (function(item) {
    return (("Array" === item.constructor.name) ? ("[ " + (map(item, macros.quote)).join(", ") + " ]") : (("number" === typeof(item)) ? item : ("\"" + literal(item) + "\"")));
  });
  
  macros.hash = (function(pairs) {
    var pairs = Array.prototype.slice.call(arguments, 0);
    
    (function() { if ((0 !== (pairs.length % 2))) { return error(("odd number of key-value pairs in hash: " + inspect(pairs))); } }).call(this);
    var pairStrings = bulkMap(pairs, (function(key, value) {
      return (translate(key) + ": " + translate(value));
    }));;
    return ((1 >= pairStrings.length) ? ("{ " + (pairStrings).join(", ") + " }") : ("{" + indent((pairStrings).join(",\n")) + "}"));
  });
  
  var literal = (function(string) {
    return inject(string.replace(/\*/g, "_")
    .replace(/\?/g, "__QUERY")
    .replace(/!$/, "__BANG")
    .replace(/\+/, "__PLUS")
    .replace(/:/g, "__COLON"), string.match(/-(.)/g), (function(returnString, match) {
      return returnString.replace(match, (match)[1].toUpperCase());
    }));
  });
  
  var translate = (function(token, hint) {
    var hint = hint;;
    ((hint && typeof((macros)[hint]) === 'undefined') ? (function() {return hint = undefined;}).call(this) : undefined);
    return (function() { if (typeof(token) !== 'undefined') { (typeof(token) === "string" ? (function() {return token = token.trim();}).call(this) : undefined); return (function() { try { return ((token) && (token).constructor.name === "Array" ? (typeof((macros)[translate((token)[0])]) !== 'undefined' ? (macros)[translate((token)[0])].apply(undefined, token.slice(1)) : (macros)[(hint || "call")].apply(undefined, token)) : ((typeof(token) === "string" && token.match((new RegExp(("^" + sibilant.tokens.literal + "$"), undefined)))) ? literal(token) : ((typeof(token) === "string" && token.match((new RegExp("^;", undefined)))) ? token.replace((new RegExp("^;+", undefined)), "//") : ((typeof(token) === "string" && ("\"" === (token)[0] &&
     "\"" === (token.slice(-1))[0])) ? token.split("\n")
    .join("\\n\" +\n\"") : token)))); } catch (e) { return error((e.stack + "\n" + "Encountered when attempting to process:\n" + indent(inspect(token)))); } }).call(this); } }).call(this);
  });
  
  sibilant.translate = translate;
  var translateAll = (function(contents) {
    var buffer = "";;
    tokenize(contents).forEach((function(token) {
      var line = translate(token, "statement");;
      return (line ? (function() {return buffer = (buffer + line + "\n");}).call(this) : undefined);
    }));
    return buffer;
  });
  
  sibilant.translateAll = translateAll;
  ;
  return $((function() {
    var sibilant = window.sibilant,
        scripts = [  ];;
    var evalWithTryCatch = (function(js) {
      return (function() { try { return eval(js); } catch (e) { return (function() { console.log(js); throw new Error (e); }).call(this); } }).call(this);
    });
    ;
    sibilant.scriptLoaded = (function() {
      var lisp = null,
          js = null;;
      return (function() { if ((!sibilant.loadNextScript())) { return $("script[type=\"text/lisp\"]:not([src])").each((function() {
        lisp = $(this).text()
        .replace(/(^\s*\/\/\<!\[CDATA\[)|(\/\/\]\]>\s*$)/g, "");
        js = sibilant.translateAll(lisp);;
        $(this).data("js", js);
        return evalWithTryCatch(js);
      })); } }).call(this);
    });
    ;
    scripts = $.makeArray($("script[type=\"text/lisp\"][src]").map((function() {
      return this.src;
    })));;
    sibilant.loadNextScript = (function() {
      var nextScript = scripts.shift();;
      return (function() { if (typeof(nextScript) !== 'undefined') { $.get(nextScript, (function(data) {
        evalWithTryCatch(sibilant.translateAll(data));
        return sibilant.scriptLoaded();
      })); return true; } }).call(this);
    });
    ;
    return sibilant.loadNextScript();
  }));
})()
