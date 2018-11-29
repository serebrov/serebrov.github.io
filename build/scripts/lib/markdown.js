var marked = require('marked');
var Q = require('q');

module.exports = Q.denodeify(marked);
