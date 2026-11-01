---
title: "MacBook - Remote Access from iPad"
date: 2025-12-10
tags: [mac]
type: note
url: "/html/2025-12-10-macbook-remote-access-from-ipad.html"
---

There are a few solutions to have remote access from iPad to MacBook:
* [Chrome remote desktop](https://remotedesktop.google.com/?pli=1)
* [Teamviewer](https://www.teamviewer.com/)
* [Jump desktop](https://jumpdesktop.com/)
* SSH, Mac screen sharing app
* Some other options

I'll start with the simplest - Teamviewer and Jump Desktop.

<!-- more -->

# Teamviewer and Jump Desktop

Both [Teamviewer](https://www.teamviewer.com/) and [Jump Desktop](https://jumpdesktop.com/) work well and the setup is easy:
* Install the iPad app (Jump Desktop app is $15, but it is one-time payment)
* Install and run the Mac app
* Connect from the iPad app to Mac

Some notes on teamviewer vs jump desktop
- jump desktop has several input modes: standard, locked screen, pen, trackpad, direct touch (I ended up mostly using the trackpad mode)
  - teamviewer has two modes: touch and mouse, the touch mode works well and feels more intuitive than any of the jump desktop modes
- in both the mouse mode can be used to trigger hot corners and mac toolbar at the bottom
- in both I cannot use three finger gestures for mac remotely
  - I use three fingers swipe left / right to switch desktops and three fingers swipe up to show all desktops
    - instead, I have to use mouse mode and the top right hot corner that is configured to show all desktops (same as 3 finger swipe up)
  - maybe because these gestures conflict with ipad gestures? I did not find a solution for this one
- audio passthrough works in both, both create a virtual audio device that is activated during the screensharing
- jump desktop has some annoying slight vertical scroll
  - maybe because of that, I also have to scroll remote screen with two fingers (one finger scrolls the local screen, two fingers - remote)
  - this is more natural in teamviewer where I can scroll remote screen with one finger
- both have extra bar for the keyboard to add Shift, Control, CMD, Alt
  - note that for combinations like CMD+Shift+T we need to use this special bar (Shift on iPad keyboard would not be counted as a part of shortcut)
- Teamviewer: there is a problem with passing some keys from the external keyboard (connected to iPad)
  - I use Voyager (QMK keyboard), there is a problem with some keys that are on a layer
  - it looks like the layer key is interpreted as Alt, so, for example, instead of double quotes I get “” and for single I get ‘’
  - there is no such problem in Jump Desktop
- Teamviewer has an annoying issue with screen blinking and scaling for a split second
  - not sure why, maybe it reconnects to the host or something

# Chrome remote desktop

Overall it works, but less convenient than Teamviewer or Jump Desktop.

Setup:
- Go to [https://remotedesktop.google.com/access](https://remotedesktop.google.com/access)
- Install on Mac, give all the permissions (accessibility, screen recording)
- On the "access" tab - allow access, set pin code
- Open the URL above on iPad, connect to Mac

What worked:
- Remote access works
- There are two modes: touch and trackpad
- The on screen keyboard has modifier keys (Cmd, Shift, Alt, Ctrl), but I did not find Esc
- External keyboard can be connected to iPad (with USB hub)
  - I have USB-A to USB-C adapter in the hub USB-A port and the keyboard connected to it
  - Power connected to the hub too, iPad is charging from it

What did not work:
- Audio
  - not sure why, it seems that it should be working
  - maybe there is some setting or it picks up wrong output (maybe blackhole?)
- Three finger touchpad gestures (same as in Teamviewer and Jump Desktop)
  - I also tried to physically connect the trackpad to iPad, gestures operate on iPad, not on mac

Related links:
- http://www.howtogeek.com/180953/3-free-ways-to-remotely-connect-to-your-macs-desktop/
- https://www.macworld.com/article/671212/how-to-remote-access-a-mac-from-an-ipad-for-free.html
- https://www.tomsguide.com/how-to/how-to-remote-control-your-mac-from-your-iphone-or-ipad

# NoMachine

I did not try it, but [NoMachine for iOS](https://www.nomachine.com/getting-started-with-nomachine-for-ios) should also work. As far as I understand, NoMachine uses a different approach from other remote access software, having a peer-to-peer network to discover devices.

# VNC

I also did not try this, but theoretically, if there is a good VNC client for iOS, it could be used as a remote access solution to connect to the VNC server running on Mac.

# SSH, screen share app

Mac has a few tools that seem to be for the mac-to-mac remote management, but maybe some of these can also be utilized to connect from iPad (I did not try this):
- [Mac screenshare app](https://support.apple.com/guide/mac-help/share-the-screen-of-another-mac-mh14066/mac)
- [Remote login feature](https://support.apple.com/en-gb/guide/mac-help/mchlp1066/mac) that allows SSH connections
- [Apple Remote Management](https://support.apple.com/en-in/guide/mac-help/mh11851/mac).

Related [video](https://www.youtube.com/watch?v=bSLBkZB5o1o).
