---
title: Git - Your branch and 'origin/xxx' have diverged
date: 2012-02-13
tags: [git]
type: note
url: "/html/2012-02-10-git-checkout-and-track-remote-branch.html"
---

Git error (not after rebase, see below):

    Your branch and 'origin/xxx' have diverged,
    and have 1 and 1 different commit(s) each, respectively.

Error is caused by two independent commits - one (or more) on the local branch copy and other - on the remote branch copy (for example, commit by another person to the same branch)

<!-- more -->
History looks like:

```bash
    ... o ---- o ---- A ---- B  origin/branch_xxx (upstream work)
                       \
                        C  branch_xxx (your work)
```

Most easy way to solve - is to rebase commit C to the remote state:

$ git rebase origin/branch_xxx
The history will look like this:

```bash
    ... o ---- o ---- A ---- B  origin/branch_xxx (upstream work)
                              \
                               C`  branch_xxx (your work)
```

The same git error after rebase:
--------------------------------------------

This happens if you rebase the branch which was previously pushed to the origin repository.
Rebase rewrites history, so after it you'll have different local and remote state:

```bash
    Your branch and 'origin/xxx' have diverged,
    and have 1 and 1 different commit(s) each, respectively.
```

In this case this is expected. For example, we have a history like this:

```bash
    ... o ---- o ---- A ---- B  master, origin/master
                       \
                        C  branch_xxx, origin/branch_xxx
```

Now we want to rebase branch_xxx against the master branch:

```bash
    $ git checkout branch_xxx
    $ git rebase master
```

And we get "Your branch and 'origin/branch_xxx' have diverged" because the history now is this:

```bash
    ... o ---- o ---- A ---------------------- B  master, origin/master
                       \                        \
                        C  origin/branch_xxx     C` branch_xxx
```

If you absolutely sure this is your case then you can force Git to push your changes:

    $(think twice before this) git push origin branch_xxx -f

Links
--------------------------------------------

[Should I rebase master onto a branch that's been pushed?](http://stackoverflow.com/questions/34918268/should-i-rebase-master-onto-a-branch-thats-been-pushed/34946769#34946769)

[Stackoverflow - master branch and 'origin/master' have diverged, how to 'undiverge' branches'?](http://stackoverflow.com/questions/2452226/master-branch-and-origin-master-have-diverged-how-to-undiverge-branches)

[Stackoverflow - git rebase basics](http://stackoverflow.com/questions/11563319/git-rebase-basics)
