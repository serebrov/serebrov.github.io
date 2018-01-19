---
title: Disqus - code formatting and highlighting in comments
date: 2018-01-19
tags: disqus
type: note
---

It is possible to format and have syntax highlighting for code in Disqus comments.
To do that, wrap the code into `<pre><code>` tags (see the example comment to this post).

<!-- more -->

I didn't know about this feature and, acutally, I think this is an UI flaw.

It would be great to see the `formatting help` link or popup when you are editing the comment (and also the `preview` feature would be really nice to have).

It is also possible to specify the language, for example `<code class="javascript">`.

See how this code was formatted in the comment to this post:

```text
    <pre><code class="javascript">
    const verifyUser = function(username, password, callback) {
       dataBase.verifyUser(username, password, (error, userInfo) => {
           if (error) return callback(error);
           getRoles(username, userInfo, callback);
       }
    }

    const getRoles = function(username, userInfo, callback) {
       dataBase.getRoles(username, (error, roles) => {
           if (error) return callback(error)
           logAccess(username, userInfo, roles, callback);
       })
    }

    const logAccess = function(username, userInfo, roles, callback) {
       dataBase.logAccess(username, (error) => {
           if (error) return callback(error);
           callback(null, userInfo, roles);
       })
    }
    </pre></code>
```

More information in the [Disqus help - Syntax highlighting](https://help.disqus.com/customer/portal/articles/665057-syntax-highlighting).

Related topics:

* [Adding Images and Videos](https://help.disqus.com/customer/portal/articles/1360518)
* [What HTML tags are allowed within comments?](https://help.disqus.com/customer/portal/articles/466253)
* [Mentions](https://help.disqus.com/customer/portal/articles/832143)
