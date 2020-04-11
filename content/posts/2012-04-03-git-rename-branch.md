---
title:  git - rename branch (local and remote)
date: 2012-04-03
tags: [git]
type: note
url: "/html/2012-03-15-oauth-1-0.html"
---


```bash
    #rename local branch
    git branch -m old-branch-name new-branch-name

    #delete remote branch with old name
    git push origin :old-branch-name

    # create remote renamed branch
    git push origin new-branch-name
```
<!-- more -->

Links
--------
[stackoverflow](http://stackoverflow.com/questions/1526794/git-rename-remote-branch)
