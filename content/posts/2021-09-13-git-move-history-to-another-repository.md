---
title: "git - how to move files with history to another repository"
date: 2021-09-13
tags: [git]
type: post
url: "/html/2021-09-13-git-move-history-to-another-repository.html"
---

Git allows joining unrelated repositories via remotes which, in turn, allows moving files and change history between them.

Some cases when this might be needed:

- Extract part of a big repository into a separate repository, preserving change history
- Splitting big repository to a set of smaller repositories
- Merge smaller repository into a bigger one (merge in library from the external repository)

Preserving the history has an important effect: after we do the change, for example, extract a part of a bigger repository into a separate repository, we can continue moving changes between them (merge updates from the big repository to the small one and back).

Below, I am assuming the first case (extract part of the big repository), other cases can be implemented with a similar technique.

## Setup

Assuming we have a source (upstream) repository and we want to extract a top-level `/lib` folder into a separate repository, first, create a destination repository:

```
mkdir dest-repo
cd dest-repo
git init
```

Add a main repository as remote and checkout master branch:

```
git remote add -f upstream git@github.com:myaccount/main.git
git checkout -b upstream_master upstream/master
git subtree split --prefix=lib/ -b upstream_lib
```

What we do above is: add the source (upstream) repository as a remote, checkout its `master` branch to the destination repository and then use `git subtree split` to create `upstream_master_lib` branch containing only `/lib` folder with all the change history.

Now we can merge the upstream files and history from the `/lib` folder to the target `master` branch:

```bash
git checkout master
git merge upstream_lib
git push origin HEAD
```

## Update from upstream

Pull recent upstream repository master branch and re-split it to a new branch:

```
git checkout upstream_master
git pull
git subtree split --prefix=lib/ -b upstream_lib_YYYY.MM.DD
```

Merge the update:

```
git checkout master
git merge upstream_lib_YYYY.MM.DD
git push origin HEAD
```
