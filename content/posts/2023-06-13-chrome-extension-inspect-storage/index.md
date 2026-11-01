---
title: "How to inspect extension `chrome.storage` in Chrome DevTools"
date: 2023-06-13
tags: [web]
type: note
url: "/html/2023-06-13-chrome-extension-inspect-storage.html"
---

The extension storage is not displayed under the "Application" tab in Chrome DevTools, but
it is possible to access it via the javascript console:

* Open some web page, open Chrome DevTools
* In the javascript console, select the extension context (the drop-down with "top" in it)
* Use `chrome.storage.local` to access the local storage

The `chrome.storage.local` is a [StorageArea](https://developer.chrome.com/docs/extensions/reference/storage/#type-StorageArea) 
object and it has methods to get and set values.

We can also print the entire storage by passing the `null` to the `get` method
with `chrome.storage.local.get(null).then((data) => console.log(data))`.

<!-- more -->

![extension storage access](2023-06-13-chrome-extension-storage.png)

The demo:

{{< video src="2023-06-13-chrome-extension-storage.mp4" type="video/mp4">}}
