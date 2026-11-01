---
title: "MacBook - How to keep it on with lid closed, clamshell mode"
date: 2025-12-10
tags: [mac]
type: note
url: "/html/2025-12-10-macbook-keep-on-with-lid-closed-clamshell-mode.html"
---

I am testing the [remote desktop to access MacBook](./2025-12-10-macbook-remote-access-from-ipad.html) and it is inconvenient that MacBook needs to stay with the lid open. Otherwise, if the lid is closed, the laptop goes to sleep and makes it impossible to connect to it.

The solution is to have MacBook in a ["clamshell mode"](https://www.google.com/search?q=macbook+clamshell+mode) which is enabled when there is an external display, mouse and keyboard connected to the laptop.

To emulate the display (which I don't have), it is possible to use the "hdmi dummy plug" or "hdmi headless adapters" like this [Fueran 4K HDR HDMI Dummy Plug](https://www.amazon.com/dp/B06XSZR7CG):

![fueran hdmi dummy adapter](fueran_hdmi_dummy_adapter_600.jpg)

<!-- more -->

The Fueran HDMI adapter works for me and in my tests it is enough to have it and the external keyboard and mouse are not necessary.

Settings that may also be needed to support the clamshell mode:
* System Settings -> Battery
  * Click Options
  * "Prevent automatic sleeping on power adapter when the display is off." -> On

Maybe related:
* System Settings -> Lock Screen
  * "Turn display off on power adapter when inactive" recommended to set to "Never"
  * I have it 1 hour, seems to work, so maybe this is not needed.

Resources:
* [Share your Mac resources when it’s in sleep](https://support.apple.com/guide/mac-help/share-your-mac-resources-when-its-in-sleep-mh27905/mac)
* [Set sleep and wake settings for your Mac](https://support.apple.com/guide/mac-help/set-sleep-and-wake-settings-mchle41a6ccd/mac)
* [How to close MacBook and Use Monitor (Clamshell Mode)](https://discussions.apple.com/thread/253886983?sortBy=rank)