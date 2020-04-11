---
title: selenium - run tests on a virtual display
date: 2012-02-20
tags: [selenium]
type: note
url: "/html/2012-02-20-selenium-run-on-virtual-display.html"
---

Selenium tests require browser to run, so usually we run them on the X-server enabled machine.
But in some cases, like CI system running on the headless EC2 instance, we want to run it on the virtual display.
This can be done using xvfb (X virtual framebuffer).

<!-- more -->
Set up
-------

Install xvfb

```bash
    sudo apt-get install xvfb
```

Install x11vnc

```bash
    sudo apt-get install x11vnc
```

Run tests on virtual display
----------------------------

Start xvbf (virtual display number 99)

```bash
    Xvfb -ac :99
```

Tell tests to run on virtual display

```bash
    export DISPLAY=:99
```

Or inside the test code (python)

```bash
    os.environ['DISPLAY'] = ':99'
    ...
    selenium = webdriver.Firefox(firefox_profile=ffp, firefox_binary=ffb)
    ...
```

Watch tests running on virtual display
--------------------------------------

Start x11vnc server on the same display:

```bash
    x11vnc -display :99
```

Use vnc client (for example, [gtkvncviewer](https://launchpad.net/gtkvncviewer)) to connect to the localhost and watch how tests are running.

Links
-----------------
[Stackoverflow](http://serverfault.com/questions/273095/connect-to-xvfb-remote-to-fix-firefox-headless-crash)

[Xvfb + Firefox](http://www.semicomplete.com/blog/geekery/xvfb-firefox.html)

[Hudson Ci Server Running Selenium/Webdriver Cucumber In Headless Mode Xvfb](http://markgandolfo.com/?p=47)



