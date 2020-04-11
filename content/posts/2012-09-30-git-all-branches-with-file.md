---
title: git - find all branches where file was changed
date: 2012-09-30
tags: [git]
type: note
---

[Solution from stackoverflow](http://stackoverflow.com/questions/6258440/find-a-git-branch-containing-changes-to-a-given-file).

Find all branches which contain a change to FILENAME (even if before the (non-recorded) branch point):

```bash
    git log --all --format=%H FILENAME | while read f; do git branch --contains $f; done | sort -u
```

<!-- more -->
Manually inspect:

```bash
    gitk --all --date-order -- FILENAME
```

Find all changes to FILENAME not merged to master:

```bash
    git for-each-ref --format="%(refname:short)" refs/heads | grep -v master | while read br; do git cherry master $br | while read x h; do if [ "`git log -n 1 --format=%H $h -- FILENAME`" = "$h" ]; then echo $br; fi; done; done | sort -u
```
