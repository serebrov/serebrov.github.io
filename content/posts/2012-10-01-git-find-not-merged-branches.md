---
title: git - find not merged branches
date: 2012-10-01
tags: [git]
type: note
url: "/html/2012-10-01-git-find-not-merged-branches.html"
---

Branches that were not merged with master:

```bash
git branch -a --no-merged  (or git branch -a --no-merged  master)
```

Branches that were merged with `feature`:

```bash
git branch -a --merged feature
```

Branches that were merged not with `feature`:

```bash
git branch -a --no-merged feature
```

<!-- more -->

## Reference

The [git-branch(1)](http://www.kernel.org/pub/software/scm/git/docs/git-branch.html) command:

* with `--contains` flag shows only the branches that contain the named commit (in other words, the branches whose tip commits are descendants of the named commit).
* with `--merged` shows only branches merged into the named commit (i.e. the branches whose tip commits are reachable from the named commit) will be listed.
* with `--no-merged` shows only branches not merged into the named commit will be listed
* if the <commit> argument is missing, it defaults to HEAD (i.e. the tip of the current branch).
