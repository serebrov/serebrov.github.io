---
title: "git - use kdiff3 as a diff/merge tool"
date: 2023-06-11
tags: [git]
type: note
url: "/html/2023-06-11-git-use-kdiff3-as-difftool.html"
---

To use kdiff3 as your diff tool and merge tool in git, run the following commands:

```bash   
git config --global mergetool.kdiff3.cmd 'kdiff3 "$BASE" "$LOCAL" "$REMOTE" -o "$MERGED"'
git config --global merge.tool kdiff3
git config --global difftool.kdiff3.cmd 'kdiff3 "$LOCAL" "$REMOTE"'
git config --global diff.tool kdiff3
```

<!-- more -->

Alternatively, edit the `~/.gitconfig` and add settings there:

```
[mergetool "kdiff3"]
	cmd = kdiff3 $LOCAL $REMOTE $BASE -o $MERGED
[diff "kdiff3"]
	cmd = kdiff3 $LOCAL $REMOTE
[merge]
	tool = kdiff3
[diff]
	tool = kdiff3
```
