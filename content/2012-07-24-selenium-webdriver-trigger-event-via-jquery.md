---
title: selenium webdriver - trigger event on element via jQuery
date: 2012-07-24
tags: selenium
---

The 'executeScript' method of the webdriver receives additional 'arguments' variable and we can pass WebElement instances to the script. So trigger an event on the elemen can be done like this (python):

    event = 'click' #or 'hover' or any other
    script = "$(arguments[0]).trigger('"+event+"')"
    webdriver.execute_script(script, web_element)

<!-- more -->
Links
--------------------------------------------
[Stackoverflow question](http://stackoverflow.com/questions/5490523/selecting-and-identifying-element-with-jquery-to-use-it-in-selenium-2-java-api)
