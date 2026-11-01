---
title: git - remove already deleted files
date: 2012-04-03
tags: [git]
type: note
url: "/html/2012-10-01-git-rm-deleted-files.html"
---

To remove files that were already deleted on the file system, run `git add` with `-u` flag:

```bash
git status
D abc.c

git add -u
```

This tells git to automatically stage tracked files - including deleting the previously tracked files.

<!-- more -->

[Stackoverflow: How do I commit all deleted files in Git?](http://stackoverflow.com/questions/1402776/how-do-i-commit-all-deleted-files-in-git)
