process.chdir(__dirname + "/app");

var coffee = require("coffee-script")
  , ss = require("socketstream");

ss.load();
ss.start.single();