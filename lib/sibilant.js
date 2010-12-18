var sibilant = exports,
    sys = require("sys"),
    import = require("sibilant/import"),
    error = (function(str) {
  throw new Error (str);
}),
    inspect = sys.inspect;
import(require("sibilant/functional"));

sibilant.tokens = {  };
(sibilant.tokens)["regex"] = "(\\/(\\\\\\\/|[^\\/\\n])+\\/[glim]*)";
(sibilant.tokens)["comment"] = "(;.*)";
(sibilant.tokens)["string"] = "(\"(([^\"]|(\\\\\"))*[^\\\\])?\")";
(sibilant.tokens)["number"] = "(-?[0-9.]+)";
(sibilant.tokens)["literal"] = "([*.$a-zA-Z-=+][*.a-zA-Z0-9-=+]*(\\?|!)?)";
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
    return (function() {
      if ((parseStack.length === 0)) {
        throw new Error (("unbalanced parens:\n" + inspect(parseStack)));
      } else {
        return undefined;
      };
    })();
  });
  ;
  var handleToken = (function(token) {
    var special = (token)[0],
        token = token;;
    (function() {
      if ((special === "'")) {
        token = token.slice(1);;
        increaseNesting();
        return acceptToken("quote");;
      } else {
        return special = false;;
      };
    })();
    specials.unshift((!!(special)));
    (function() {
      switch(token) {
      case "(":
        return increaseNesting();
      
      case "]":
      case "}":
      case ")":
        return decreaseNesting();
      
      case "{":
        increaseNesting();
        return acceptToken("hash");
      
      case "[":
        increaseNesting();
        return acceptToken("list");
      
      default:
        return (function() {
          if (token.match((new RegExp(("^" + sibilant.tokens.number + "$"), undefined)))) {
            return acceptToken(parseFloat(token));
          } else {
            return acceptToken(token);
          };
        })();
      }
    })();
    return (function() {
      if (((token !== "(") && specials.shift())) {
        return decreaseNesting();
      } else {
        return undefined;
      };
    })();
  });
  ;
  var orderedRegexen = map(sibilant.tokenPrecedence, (function(x) {
    return (sibilant.tokens)[x];
  })),
      masterRegex = (new RegExp((orderedRegexen).join("|"), "g"));;
  string // chain
    .match(masterRegex)
    .forEach(handleToken)
  ;
  (function() {
    if ((parseStack.length > 1)) {
      return error("unexpected EOF, probably missing a )\n", inspect((parseStack)[0]));
    } else {
      return undefined;
    };
  })();
  return tokens;
});;
;

var indent = (function(args) {
  var args = Array.prototype.slice.call(arguments, 0);
  
  return (compact(args) // chain
    .join("\n")
    .replace(/^/, "\n")
    .replace(/\n/g, "\n  ")
   + "\n");
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
  return (function() {
    if ((token) && (token).constructor.name === "Array") {
      return (function() {
        switch((token)[0]) {
        case "return":
        case "throw":
        case "do":
          return translate(token);
        
        case "delete":
          var deleteMacro = (macros)["delete"];;
          return (function() {
            if ((token.length < 3)) {
              return defaultReturn;
            } else {
              return (deleteMacro.apply(undefined, token.slice(1, -1)) + "\nreturn " + deleteMacro((token.slice(-1))[0]));
            };
          })();
        
        case "=":
          return (function() {
            if ((token.length < 4)) {
              return defaultReturn;
            } else {
              return ((macros)["="].apply(undefined, token.slice(1, (token.length - 2))) + "\nreturn " + (macros)["="].apply(undefined, token.slice(-2)));
            };
          })();
        
        case "set":
          return (function() {
            if ((token.length < 5)) {
              return defaultReturn;
            } else {
              var obj = (token)[1],
                  nonReturnPart = token.slice(2, (token.length - 2)),
                  returnPart = token.slice(-2);;
              nonReturnPart.unshift(obj);
              returnPart.unshift(obj);
              return (macros.set.apply(undefined, nonReturnPart) + "\nreturn " + macros.set.apply(undefined, returnPart));;
            };
          })();
        
        default:
          return defaultReturn;
        }
      })();
    } else {
      return defaultReturn;
    };
  })();
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
  }))).join("\n");
});

macros.call = (function(fName, args) {
  var args = Array.prototype.slice.call(arguments, 1);
  
  return (translate(fName) + "(" + (map(args, translate)).join(", ") + ")");
});

macros.def = (function(fName, argsAndBody) {
  var argsAndBody = Array.prototype.slice.call(arguments, 1);
  
  var fNameTr = translate(fName),
      start = (function() {
    if (/\./(fNameTr)) {
      return "";
    } else {
      return "var ";
    };
  })();;
  return (start + fNameTr + " = " + macros.fn.apply(undefined, argsAndBody) + ";\n");
});

macros.mac = (function(name, argsAndBody) {
  var argsAndBody = Array.prototype.slice.call(arguments, 1);
  
  var js = macros.fn.apply(undefined, argsAndBody),
      name = translate(name);;
  (function() {
    try {
      return (macros)[name] = eval(js);;
    } catch (e) {
      return error(("error in parsing macro " + name + ":\n" + indent(js)));
    }
  })();
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
    return (function() {
      if (((arg)[0] === "&")) {
        return last = arg.slice(1);;
      } else {
        args.push([ (last || "required"), arg ]);
        return last = null;;;
      };
    })();
  }));
  (function() {
    if (last) {
      return error(("unexpected argument modifier: " + last));
    } else {
      return undefined;
    };
  })();
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
  return (function() {
    if (typeof(rest) !== 'undefined') {
      return (argsString + "var " + translate((rest)[1]) + " = Array.prototype.slice.call(arguments, " + args.length + ");\n");
    } else {
      return argsString;
    };
  })();
});

// brain 'splode
macros.fn = (function(arglist, body) {
  var body = Array.prototype.slice.call(arguments, 1);
  
  var args = transformArgs(arglist),
      rest = (select(args, (function(arg) {
    return ("rest" === (arg)[0]);
  })))[0],
      docString = undefined;;
  (body)[(body.length - 1)] = [ "return", (body)[(body.length - 1)] ];;
  (function() {
    if (((typeof((body)[0]) === "string") && (body)[0].match(/^".*"$/))) {
      return docString = ("/* " + eval(body.shift()) + " */\n");;
    } else {
      return undefined;
    };
  })();
  var noRestArgs = (function() {
    if (rest) {
      return args.slice(0, -1);
    } else {
      return args;
    };
  })(),
      argsString = buildArgsString(noRestArgs, rest);;
  return ("(function(" + (map(args, (function(arg) {
    return translate((arg)[1]);
  }))).join(", ") + ") {" + indent(docString, argsString, (map(body, (function(stmt) {
    return (translate(stmt) + ";");
  }))).join("\n")) + "})");
});

macros.quote = (function(item) {
  return (function() {
    if (("Array" === item.constructor.name)) {
      return ("[ " + (map(item, macros.quote)).join(", ") + " ]");
    } else {
      return (function() {
        if (("number" === typeof(item))) {
          return item;
        } else {
          return ("\"" + literal(item) + "\"");
        };
      })();
    };
  })();
});

macros.hash = (function(pairs) {
  var pairs = Array.prototype.slice.call(arguments, 0);
  
  (function() {
    if ((0 !== (pairs.length % 2))) {
      return error(("odd number of key-value pairs in hash: " + inspect(pairs)));
    };
  })();
  var pairStrings = bulkMap(pairs, (function(key, value) {
    return (translate(key) + ": " + translate(value));
  }));;
  return (function() {
    if ((1 >= pairStrings.length)) {
      return ("{ " + (pairStrings).join(", ") + " }");
    } else {
      return ("{" + indent((pairStrings).join(",\n")) + "}");
    };
  })();
});

var literal = (function(string) {
  return inject(string // chain
    .replace(/\*/g, "_")
    .replace(/\?$/, "__QUERY")
    .replace(/!$/, "__BANG")
    .replace(/\+/, "__PLUS")
  , string.match(/-(.)/g), (function(returnString, match) {
    return returnString.replace(match, (match)[1].toUpperCase());
  }));
});

var translate = (function(token, hint) {
  var hint = hint;;
  (function() {
    if ((hint && typeof((macros)[hint]) === 'undefined')) {
      return hint = undefined;;
    } else {
      return undefined;
    };
  })();
  return (function() {
    if (typeof(token) !== 'undefined') {
      (function() {
        if (typeof(token) === "string") {
          return token = token.trim();;
        } else {
          return undefined;
        };
      })();
      return (function() {
        try {
          return (function() {
            if ((token) && (token).constructor.name === "Array") {
              return (function() {
                if (typeof((macros)[translate((token)[0])]) !== 'undefined') {
                  return (macros)[translate((token)[0])].apply(undefined, token.slice(1));
                } else {
                  return (macros)[(hint || "call")].apply(undefined, token);
                };
              })();
            } else {
              return (function() {
                if ((typeof(token) === "string" && token.match((new RegExp(("^" + sibilant.tokens.literal + "$"), undefined))))) {
                  return literal(token);
                } else {
                  return (function() {
                    if ((typeof(token) === "string" && token.match((new RegExp("^;", undefined))))) {
                      return token.replace((new RegExp("^;+", undefined)), "//");
                    } else {
                      return (function() {
                        if ((typeof(token) === "string" && ("\"" === (token)[0] &&
                         "\"" === (token.slice(-1))[0]))) {
                          return token // chain
                            .split("\n")
                            .join("\\n\" +\n\"")
                          ;
                        } else {
                          return token;
                        };
                      })();
                    };
                  })();
                };
              })();
            };
          })();
        } catch (e) {
          return error((e.stack + "\n" + "Encountered when attempting to process:\n" + indent(inspect(token))));
        }
      })();
    };
  })();
});

sibilant.translate = translate;
var translateAll = (function(contents) {
  var buffer = "";;
  tokenize(contents).forEach((function(token) {
    var line = translate(token, "statement");;
    return (function() {
      if (line) {
        return buffer = (buffer + line + "\n");;
      } else {
        return undefined;
      };
    })();
  }));
  return buffer;
});

sibilant.translateAll = translateAll;

var include = (function(file) {
  var fs = require("fs"),
      data = fs.readFileSync(file, "utf8");;
  return translateAll(data);
});

(sibilant)["include"] = include;
macros.include = (function(file) {
  return sibilant.include(eval(translate(file)));
});

sibilant.packageInfo = (function() {
  var fs = require("fs"),
      json = JSON;;
  return json.parse(fs.readFileSync((__dirname + "/../package.json")));
});

sibilant.versionString = (function() {
  var package = sibilant.packageInfo(),
      path = require("path");;
  return (package.name + " version " + package.version + "\n(at " + path.join(__dirname, "..") + ")");
});

sibilant.stripShebang = (function(data) {
  return data.replace(/^#!.*\n/, "");
});

sibilant.translateFile = (function(fileName) {
  var fs = require("fs");;
  return sibilant.translateAll(sibilant.stripShebang(fs.readFileSync(fileName, "utf8")));
});

sibilant.version = (function() {
  return (sibilant.packageInfo())["version"];
});

sibilant.include((__dirname + "/macros.lisp"));

