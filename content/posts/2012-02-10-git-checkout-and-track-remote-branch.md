---
title: git - checkout and track remote branch
date: 2012-02-01
tags: [git]
type: note
url: "/html/2012-01-24-jquery-check-version.html"
---

Note: in recent `git` versions, it is enough to do `git pull` and `git checkout feature` to checkout and start tracking the remote branch.

Before, it was necessary to use the `-t` (`--track`) flag to do that:

```bash
#creates and checks out "feature" branch that tracks "origin/feature"
$ git checkout -t origin/feature
```

<!-- more -->

Relevant part from the [checkout docs](https://git-scm.com/docs/git-checkout#Documentation/git-checkout.txt-emgitcheckoutemltbranchgt):

>  git checkout [<branch>]
>    ...
>    If <branch> is not found but there does exist a tracking branch in exactly one remote (call it <remote>) with a matching name and --no-guess is not specified, treat
>    as equivalent to
>          $ git checkout -b <branch> --track <remote>/<branch>
