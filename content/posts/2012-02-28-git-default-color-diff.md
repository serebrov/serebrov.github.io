---
title: git - colored diff, branch, etc output by default
date: 2012-02-28
tags: [git]
type: note
url: "/html/2012-02-13-git-branches-have-diverged.html"
---

To have colored git commands output, use the following command:

```bash
git config color.ui true
```

or (globally)

```bash
git config --global color.ui true
```

Alternatively, you can set color for individual git commands.

<!-- more -->

```bash
git config color.branch auto
git config color.diff auto
git config color.interactive auto
git config color.status auto
```

See also color.* options in the [git config docs](http://schacon.github.com/git/git-config.html).

Links
-----------------
[git book](http://book.git-scm.com/5_customizing_git.html)

[Color highlighted diffs with git, svn and cvs](http://stefaanlippens.net/color_highlighted_diffs_with_git_svn_cvs)



