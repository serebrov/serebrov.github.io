---
title: Node.js - how to debug mocha test with node inspector
date: 2013-12-02
tags: [node.js]
type: note
url: "/html/2013-12-02-node-debug-mocha.html"
---

To debug mocha test with [node inspector](https://github.com/node-inspector/node-inspector) use the delay before test:

<!-- more -->
```js
    beforeEach(function(done) {
        //start mocha as
        //mocha -t 10000 --debug
        setTimeout(function() {
            done();
        }, 5000);
    });
```

This way there are 5 seconds to start the node inspector and set a breakpoint.
Mocha should be lauched as this:

```bash
    $ mocha -t 10000 --debug
```

Same approach can be used not only for tests but for any short-living node app -
just wrap the startup code into the setTimeout() call.
