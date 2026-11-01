---
title: "git - cherry-pick a range of commits"
date: 2021-09-13
tags: [git]
type: post
url: "/html/2021-09-13-git-cherry-pick-a-range-of-commits.html"
---

To cherry pick a range of commits to another branch, we can use the `START^..END` commit range syntax, where `START` is the first commit in the range and `END` is the last commit:

```bash
git cherry-pick START^..END
```

## References

[How to cherry-pick a range of commits and merge them into another branch?](https://stackoverflow.com/a/1994491/4612064)
