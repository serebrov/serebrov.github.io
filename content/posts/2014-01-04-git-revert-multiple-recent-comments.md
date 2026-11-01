---
title: git - how to revert multiple recent commits
date: 2014-01-04
tags: [git]
type: note
url: "/html/2014-01-04-git-revert-multiple-recent-comments.html"
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

## Create new branch

This is a safe and simple method that does not require history rewrite: checkout the last 'good' commit and create a new branch from it:

```
git checkout G3
git checkout -b my-new-branch
```

A variation of this is to create a new branch and then cherry-pick commits you need to it:

```
git checkout master
git checkout -b my-new-branch
git cherry-pick G1
git cherry-pick G2
git cherry-pick G3
```

It is also possible to [cherry pick a range of commits](https://serebrov.github.io/html/2021-09-13-git-cherry-pick-a-range-of-commits.html) with `git cherry-pick G1^..G3`.

## Use git reset

A simple way to throw away a few recent commits is to use `git reset`.
It re-writes the commit history, so only use it when your changes are not public yet (you can do this locally or on your private branch).

The `git reset` command can be used to throw away recent commits (the `--hard` flag will also remove any local changes that are not committed yet):

```
Careful: `git reset` will rewrite history.

Careful: `--hard` will remove not-committed local changes.
```

```bash
$ git reset --hard HEAD~3
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

## Use git revert

If your changes are public already (for example, merged to `master` or other public branch), then it is better to avoid history rewrites and use `git revert` to generate anti-commit for your changes.

The `revert` command takes SHA1 of one or several commits and generates the new change to reverse the effect of these commits.

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

## Revert the commit in the middle of the history

For example, we have history like this:

```bash
G1 - G2 - G3 - B1 - G4 - G5
```

And want to revert the `B1` commit.

The safe way is to use the `git revert B1-sha1` command, as described above - it will generate an anti-commit for `B1`.

The other method is to use interactive rebase to move the bad commit to the top of the history and then remove it with `git reset`:

```bash
git rebase -i HEAD~3

pick B1-sha commit message
pick G4-sha commit message
pick G5-sha commit message
```

Here (in the file, opened by `git rebase`) we can edit the order of the commits and move the bad commit to the end of the commit history:

```bash
pick G4-sha commit message
pick G5-sha commit message
pick B1-sha commit message
```

Save the file and exit the editor. If everything is alright (commit has no dependencies), the command will be completed successfully.
Note: otherwise (you've got conflicts error) it is probably better to do `git rebase --abort` to get back to the previous state and re-consider the update strategy.

Now the history should look like this:

```bash
G1 - G2 - G3 - G4 - G5 - B1
```

And we can remove the last commit with `git reset --hard HEAD~1` (again, careful, it will remove any local uncommitted changes and will rewrite history, do not use on public branches).

## Rollback to the specific revision

The `git revert` command reverts a range of specified revisions, but sometimes we just want to restore the state of some specific revision instead of reverting commits one-by-one.

This is also how `hg revert` works in Mercurial.

This is especially useful if we want to revert past the merge point, where it can be quite difficult to use `git revert` because we will also need to specify which parent to follow at merge point (you'll see a `Commit XXX is a merge but no -m option was given.` message).

### Revert to the specific revision using git checkout

Having a history like this:

```bash

 /-- master
/
G1 - G2 - G3 - B1 - B2 - B3
                          \--- branch
```

We can rollback the branch state to `G3` commit this way:

```bash
git checkout G3-sha
git branch -D branch  # Delete existing branch
git checkout -b branch  # Checkout branch with the same name again
git push -f origin HEAD  # Force-push the new branch
```

So, basically, we are removing the existing branch and creating another branch with the same name from `G3`.

### Revert to the specific revision using git reset

The solution comes from the [Revert to a commit by a SHA hash in Git?](https://stackoverflow.com/questions/1895059/revert-to-a-commit-by-a-sha-hash-in-git/1895095#1895095) question.

Here we first hard reset the state of the repository to some previous revision and then soft reset back to current state.
The soft reset will keep file modifications, so it will bring old state back on top of the current state:

```
Careful, reset --hard will remove non-committed changes
```

```bash
$ git reset --hard 0682c06  # Use the SHA1 of the revision you want to revert to
HEAD is now at 0682c06 G3
$ git reset --soft HEAD@{1}
$ git commit -m "Reverting to the state of the project at 0682c06"
```

### Rollback to the specific revision using git read-tree

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
