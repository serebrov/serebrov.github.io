---
title: git - colored diff, branch, etc by default
date: 2012-02-28
tags: git
type: note
---


See color.* options in the [git config](http://schacon.github.com/git/git-config.html) docs:

```bash
    $ git config color.branch auto
    $ git config color.diff auto
    $ git config color.interactive auto
    $ git config color.status auto
```
<!-- more -->

Or, you can set all of them on with the color.ui option:

```bash
    $ git config color.ui true
```

or (globally)

```bash
    $ git config --global color.ui true
```

Links
-----------------
[git book](http://book.git-scm.com/5_customizing_git.html)

[Color highlighted diffs with git, svn and cvs](http://stefaanlippens.net/color_highlighted_diffs_with_git_svn_cvs)



