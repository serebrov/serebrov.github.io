var _ = require('lodash');
var path = require('path');
var glob = require("glob")
var fs = require('fs-extra');
var Q = require('q');

var Handlebars = require('handlebars');
var layouts = require('handlebars-layouts');
// some pretty usefull helpers I can use here!
require('handlebars-helpers').register(Handlebars, {});
layouts(Handlebars);

module.exports = {
    Handlebars: Handlebars
};

module.exports.register = function(tplPath) {
  return Q.nfcall(glob, tplPath, {})
    .then(function(files) {
      //Register partials
      _.each(files, function(file) {
        var name = path.basename(file, '.hbs');
        //console.log('Register partial: ' + name);
        var contents = fs.readFileSync(file).toString();
        //console.log('Register partial: ' + name);
        Handlebars.registerPartial(name, contents);
      });
      return Handlebars;
    });
};
