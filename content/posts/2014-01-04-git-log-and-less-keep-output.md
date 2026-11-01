---
title: How to keep `git log` and `git diff` output on the screen after exit
date: 2014-01-04
tags: [git]
type: note
url: "/html/2014-01-04-git-log-and-less-keep-output.html"
---

When `git` uses `less` as pager the output of commands like `git log` disappears from the console screen when you exit from less.

This is not convenient in many cases so here is how to fix this.

Just for git commands:

```bash
git config --global --replace-all core.pager "less -iXFR"
```

For `less` command, globally (including git) - add to your shell profile (`.bashrc`, `.zshrc`, etc):

```bash
export LESS=-iXFR
```

<!-- more -->

Options we set for `less`:

* -i - ignore case when searching (but respect case if search term contains uppercase letters)
* -X - do not clear screen on exit
* -F - exit if text is less then one screen long
* -R - was on by default on my system, something related to colors

Links
============================================
[Linux Questions: more or less - but less does not keep its output on the screen](http://www.linuxquestions.org/questions/linux-software-2/more-or-less-but-less-does-not-keep-its-output-on-the-screen-938187/)
