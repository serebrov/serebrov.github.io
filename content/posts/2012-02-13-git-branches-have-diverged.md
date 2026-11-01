---
title: git - your branch and 'origin/xxx' have diverged error
date: 2012-02-13
tags: [git]
type: note
url: "/html/2012-02-10-git-checkout-and-track-remote-branch.html"
---

Git error:

    Your branch and 'origin/xxx' have diverged,
    and have 1 and 1 different commit(s) each, respectively.

The error is caused by two independent commits - one (or more) on the local branch copy and other - on the remote branch copy (for example, commit by another person to the same branch).

Another case for the error is `git rebase` (error is expected, see below).

<!-- more -->
The history looks like this:

```
    ... o ---- o ---- A ---- B  origin/branch_xxx (upstream work)
                       \
                        C  branch_xxx (your work)
```

The solution depends on what has actually happened, the reason why the upstream state has changed.
If someone else is also working on the same branch, the good way to solve it is to rebase the commit `C` on top of the remote state:

```bash
$ git rebase origin/branch_xxx 
```

The history after the rebase will look like this:

```
    ... o ---- o ---- A ---- B  origin/branch_xxx (upstream work)
                              \
                               C`  branch_xxx (your work)
```

Another way to fix the issue is to merge the upstream branch state to local:

```bash
$ git merge origin/branch_xxx
```

The history after will look like this:

```
    ... o ---- o ---- A ---- C ---- B  --- [merge commit]
```


The same git error after rebase:
--------------------------------------------

This happens if you rebase the branch which was previously pushed to the origin repository, for example, we start with a state like this:

```
    ... o ---- o ---- A ---- B  master, origin/master
                       \
                        C  branch_xxx, origin/branch_xxx
```

Now we want to rebase branch_xxx against the master branch:

```bash
git checkout master
git pull
git checkout branch_xxx
git rebase master
```

Now local state of the `mybranch` and `origin/mybranch` state will diverge.
This is expected as rebase rewrites history, so after it you'll have different local and remote state:

```
    ... o ---- o ---- A ---------------------- B  master, origin/master
                       \                        \
                        C  origin/branch_xxx     C` branch_xxx
```

```bash
$ git status
Alias tip: g status
On branch branch
Your branch and 'origin/branch' have diverged,
and have 1 and 1 different commits each, respectively.
  (use "git pull" to merge the remote branch into yours)
```


If you absolutely sure this is your case then you can force Git to push your changes:

```bash
git push -f origin branch_xxx
```

Links
--------------------------------------------

[Should I rebase master onto a branch that's been pushed?](http://stackoverflow.com/questions/34918268/should-i-rebase-master-onto-a-branch-thats-been-pushed/34946769#34946769)

[Stackoverflow - master branch and 'origin/master' have diverged, how to 'undiverge' branches'?](http://stackoverflow.com/questions/2452226/master-branch-and-origin-master-have-diverged-how-to-undiverge-branches)

[Stackoverflow - git rebase basics](http://stackoverflow.com/questions/11563319/git-rebase-basics)
