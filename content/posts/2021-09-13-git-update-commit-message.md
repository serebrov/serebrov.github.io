---
title: "git - update commit message"
date: 2021-09-13
tags: [git]
type: post
url: "/html/2021-09-13-git-update-commit-message.html"
---

# Simple: Change Last Commit Message

To change the last commit message, use `commit` with `--amend` flag:

```
Careful: `commit --amend` will rewrite history,
do not use on public branches.
```

```bash
$ git commit --amend
```

It will open an editor and change the commit message, changes will be applied after saving the file and closing the editor.

# Advanced: Change Any Commit Message or Multiple Commit Messages

Besides other things, interactive rebase allows editing commit messages:

```bash
git rebase -i HEAD~3

pick SHA-A commit message
pick SHA-B commit message
pick SHA-C commit message
```

Do not change commit messages just yet, only change `pick` in the first column to `r` (or full `reword`):

```bash
pick SHA-A commit message
r SHA-B commit message
r SHA-C commit message
```

Here we schedule commit message update for `SHA-B` and `SHA-C` commits.
After the file is saved, git will open the editor once more for each of the marked commits where we can edit the commit message.

<!-- more -->

# Alternative: Cherry Pick Commits and Update Messages

This might be useful if we want to pick some commits from the branch and update commit messages:

```
# create the new branch
git checkout -b new-branch

# for every commit to pick
git cherry-pick commit-sha
git commit --amend
```

So we cherry pick needed commits and then edit commit messages with `commit --amend`.
