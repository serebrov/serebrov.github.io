---
title: There Is No Callback Hell In JavaScript
date: 2018-01-19
tags: [js]
type: post
url: "/html/2018-01-19-there-is-no-callback-hell.html"
---

There is no "callback hell" in Javascript, it is just a bad programming style.
The infamous JavaScript "callback hell" can easily be fixed by un-nesting all the callbacks into separate functions.
<!-- more -->

Here is an example:

```javascript
const verifyUser = function(username, password, callback) {
   dataBase.verifyUser(username, password, function(error, userInfo) {
       if (error) {
           callback(error);
       } else {
           dataBase.getRoles(username, function(error, roles) {
               if (error) {
                   callback(error);
               } else {
                   dataBase.logAccess(username, function(error) {
                       if (error) {
                           callback(error);
                       } else {
                           callback(null, userInfo, roles);
                       }
                   })
               }
           })
       }
   })
};
```

The same code with separate functions instead of inline callbacks:

```javascript
const verifyUser = function(username, password, callback) {
   dataBase.verifyUser(username, password, function(error, userInfo) {
       if (error) return callback(error);
       getRoles(username, userInfo, callback);
   }
}

const getRoles = function(username, userInfo, callback) {
   dataBase.getRoles(username, function(error, roles) {
       if (error) return callback(error);
       logAccess(username, userInfo, roles, callback);
   })
}

const logAccess = function(username, userInfo, roles, callback) {
   dataBase.logAccess(username, function(error) {
       if (error) return callback(error);
       callback(null, userInfo, roles);
   })
}
```

It is much more readable, manageable and reusable than the approach with inline functions.
In fact, there is no "callback hell" in here - there are simply no nested callbacks in this code anymore.

This way, the "callback hell" is simply a bad style of writing code that is easy to avoid.

Libraries like [step](https://github.com/creationix/step), [async](https://github.com/caolan/async), promises or async/await all provide a way to manage the asynchronous code.
These methods may be less verbose or more convenient than "regular" callback functions, but callbacks can work too.
