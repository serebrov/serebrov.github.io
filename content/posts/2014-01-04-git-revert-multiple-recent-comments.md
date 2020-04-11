---
title: Git - how to revert multiple recent commits
date: 2014-01-04
tags: [git]
type: note
---

Let's assume we have a history like this:

```bash
G1 - G2 - G3 - B1 - B2 - B3
```

Where G1-G3 are 'good' commits and B1-B3 are 'bad' commits and we
want to revert them.
<!-- more -->

[Here is the shell script](/git-revert/init.sh) to create the
revision history like above, you can use it to try and see the effect of different
commands.

## git reset

The first method is a simple way to throw away few recent commits,
it re-writes the commit history, so only use it when your changes
are not pushed to the server yet (or when you are 100% sure about what
you are doing).

The `git reset` command can be used this way (the `--hard` flag will
also clear any pending changes which are not commited yet):

```bash
$ git reset --hard HEAD~3  # Careful, will remove not-commited changes
```

Here we can refer to `B3` as `HEAD`, `B2` is `HEAD~1`, `B1` is `HEAD~2`.
This way the last good commit `G3` is `HEAD~3`:

```bash
G1 - G2 - G3 - B1 - B2 - B3
           \    \    \    \-- HEAD
            \    \    \------ HEAD~1
             \    \---------- HEAD~2
              \-------------- HEAD~3
```

## git revert

If your changes are pushed to the remote repository or you want in general to aviod
changing the commit history, then it is better to use `revert`.

The `revert` command takes SHA1 of one or several commits and
generates the new change to reverse the effect of these commits.

> Note for Mercurial users: in Mercurial, the `revert` command works differently -
it takes the revision identifier and reverts the state of the repository to that
revision. So we can ask Mercurial to `revert current state to the state of the revision G3`.
> In git, the `revert` takes one or multiple revision identifiers and reverts
the effect of the specified revisions. When we are talking to git, we ask it to
`revert the effect of revisions B3, B2, B1`.

Here is how we can use `git revert`:

```bash
$ git revert --no-commit HEAD~2^..HEAD
```

Or:

```bash
$ git revert --no-commit HEAD~3..HEAD
```

We need to revert a range of revisions from B1 to B3.
The range specified with two dots like `<rev1>..<rev2>` includes only
commits reachable from `<rev2>`, but not reachable from `<rev1>` (see `man -7 gitrevisions`).

Since we need to include B1 (represented by HEAD~2) we use HEAD~2^ (its parent) or HEAD~3 (also parent of HEAD~2).
The `HEAD~2^` syntax is more convenient if commit SHAs are used to name commits.

The `--no-commit` option tells git to do the revert, but do not
commit it automatically.

So now we can review the repository state and commit it.
After that we will get the history like this:

```bash
G1 - G2 - G3 - B1 - B2 - B3 - R`
```

Where `R'` is a revert commit which will return repository state to the commit `G3`.
Run git diff to check this (output should be empty):

```bash
$ git diff HEAD~4 HEAD
```

Another way to run revert is to specify commits one by one from newest to oldest:

```bash
$ git revert --no-commit HEAD HEAD~1 HEAD~2
```

In this case there is no need to specify HEAD~3 since it is a good commit we do not want to revert.
This is very useful if we want to revert some specific commits, for example, revert `B3` and `B1`, but keep `B2`:

```bash
$ git revert --no-commit HEAD HEAD~2
```

## Revert to the specific revision

The `git revert` command reverts a range of specified revisions, but sometimes we just
want to restore the state of some specific revision instead of reverting commits one-by-one.
This is also how `hg revert` works in Mercurial.

This is especially useful if we want to revert past merge point, where it can be quite
difficult to use `git revert` because we will also need to specify which parent to
follow at merge point (you'll see a `Commit XXX is a merge but no -m option was given.` message).

### Revert to the specific revision using git reset

The solution comes from the [Revert to a commit by a SHA hash in Git?](https://stackoverflow.com/questions/1895059/revert-to-a-commit-by-a-sha-hash-in-git/1895095#1895095) question.

Here we first hard reset the state of the repository to some previous revision and then soft reset back to current state.
The soft reset will keep file modifications, so it will bring old state back on top of the current state:

```bash
# Careful, reset --hard will remove non-commited changes
$ git reset --hard 0682c06  # Use the SHA1 of the revision you want to revert to
HEAD is now at 0682c06 G3
$ git reset --soft HEAD@{1}
$ git commit -m "Reverting to the state of the project at 0682c06"
```

### Revert to the specific revision using git read-tree

This solution comes from [How to do hg revert --all with git?](https://stackoverflow.com/questions/30572775/how-to-do-hg-revert-all-with-git) question:

```bash
git read-tree -um @ 0682c06  # Use the SHA1 of the revision you want to revert to
```

The `-m` option instructs `read-tree` to merge the specified state and `-u` will update work tree with the results of the merge.


Links
============================================
[Stackoverflow: Revert multiple git commits](http://stackoverflow.com/questions/1463340/revert-multiple-git-commits)

[Stackoverflow: Revert a range of commits in git](http://stackoverflow.com/questions/4991594/revert-a-range-of-commits-in-git)

[Stackoverflow: Git diff .. ? What's the difference between having .. and no dots](http://stackoverflow.com/questions/7251477/git-diff-whats-the-difference-between-having-and-no-dots)

[What's the difference between HEAD^ and HEAD~ in Git?](http://stackoverflow.com/questions/2221658/whats-the-difference-between-head-and-head-in-git)

[Stackoverflow: Revert to a commit by a SHA hash in Git?](https://stackoverflow.com/questions/1895059/revert-to-a-commit-by-a-sha-hash-in-git/1895095#1895095)

[How to do hg revert --all with git?](https://stackoverflow.com/questions/30572775/how-to-do-hg-revert-all-with-git)
