---
title: "node - localhost connection error ECONNREFUSED ::1:4723 in node 17 and node 18"
date: 2023-07-28
tags: [node.js]
type: note
url: "/html/2023-07-28-node-econnrefused-localhost.html"
---

The upgrade to node 18 broke some things on CI that looked strange at first:

1. The `npx wait-on` checks started showing connection errors.
1. The webdriver.io tests for native apps failed, also with connection errors.

The errors look like this:

> Unable to connect to "http://localhost:4723/", make sure browser driver is running on that address. 
> ..
> ERROR webdriver: RequestError: connect ECONNREFUSED ::1:4723

The `localhost` resolves to IPv6 address `::1` and the connection fails as the server (Appium) only runs on IPv4 address (`127.0.0.1`).

<!-- more -->

The problem is caused by the change in Node's DNS lookup procedure and
starting with Node 17, it does not resolve `localhost` to `127.0.0.1` (IPv4 address)
by default (instead, it got resolved to the IPv6 `::1` address which caused a connection error):

>  Node.js no longer re-sorts results of IP address lookups and returns them as-is (i.e. it no longer ignores how your OS has been configured)

Discussion is here: https://github.com/nodejs/node/issues/40702.

Possible solutions are:

* Replace `localhost` with `127.0.0.1` on the client side
* Update your server applications to listen to both IPv4 (`127.0.0.1`) and IPv6 addresses (`::1`)
* Downgrade to Node 16 or upgrade to Node 20 (one more change here to automatically fallback to IPv4, so it works again).

For example, to fix the problem with `npx wait-on http://localhost:8080`, change it to `npx wait-on http://127.0.0.1:8080`.
If you also control the server-side code, consider starting the server both on IPv4 and IPv6 addresses.

It becomes more complex if you do not have control over either the client or the server code.
In the case of native webdriver.io tests, it both starts the server (Appium)
and acts as a client, trying to connect to it via `http://localhost:4723`.

I found a configuration option to change the
[port](https://webdriver.io/docs/appium-service/#options),
but I didn't find a way to configure the Appium server address
(to change `localhost` to `127.0.0.1`).

As a simpler solution, I switched to Node 20 before running tests:

```bash
nvm install 20
nvm use 20
cd e2e-webdriver
npm run test:ios
```

This way tests run with Node 20 that has a fall-back to IPv4 and the connection works.
