var marked = require('marked');
var Q = require('q');

// Async highlighting with pygmentize-bundled
marked.setOptions({
  highlight: function (code, lang, callback) {
    require('pygmentize-bundled-cached')({ lang: lang, format: 'html' }, code, function (err, result) {
      var data = result ? result.toString(): "";
      callback(err, data);
    });
  }
});

module.exports = Q.denodeify(marked);
