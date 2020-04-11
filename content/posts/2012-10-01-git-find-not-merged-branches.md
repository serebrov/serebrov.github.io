---
title: git - find not merged branches
date: 2012-10-01
tags: [git]
type: note
url: "/html/2012-10-01-git-find-not-merged-branches.html"
---


<!-- more -->
[git-branch(1)](http://www.kernel.org/pub/software/scm/git/docs/git-branch.html)

With --contains, shows only the branches that contain the named commit
(in other words, the branches whose tip commits are descendants of the named commit).

With --merged, only branches merged into the named commit
(i.e. the branches whose tip commits are reachable from the named commit) will be listed.

With --no-merged only branches not merged into the named commit will be listed.
If the <commit> argument is missing it defaults to HEAD (i.e. the tip of the current branch).

Not merged with master:

    git branch -a --no-merged  (or git branch -a --no-merged  master)

Merged with `feature`:

    git branch -a --merged feature

Not merged with `feature`:

    git branch -a --no-merged feature
