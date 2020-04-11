---
title: phpmyadmin and eaccelerator problem
date: 2012-04-03
tags: [php]
type: note
url: "/html/2012-10-09-phpmyadmin-and-eaccelerator-problem.html"
---

Error when trying to access phpmyadmin (in Chrome):

    Error 324 (net::ERR_EMPTY_RESPONSE): The server closed the connection without sending any data.

<!-- more -->
The easiest way to fix I found is to disable eaccelerator in .htaccess (create it in the phpmyadmin root folder and add this line:

    php_flag eaccelerator.enable 0
