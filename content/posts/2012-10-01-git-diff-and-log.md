---
title: git - viewing changes - diff and log
date: 2012-10-01
tags: [git]
type: note
url: "/html/2012-10-01-git-diff-and-log.html"
---

## Diff and log between two branches (all changes on both branches)

To see all changes between two branches, use `diff` with two or three dots and `log` with three dots between branch names.

Note: the confusing part is that `log` with two dots only shows changes on one branch, while `diff` with two dots includes changes on both branches (showing changes from one branch as removed and from another branch - as added).
See the section below on how to see only new changes on the branch.

For example, we have a history like this:

```
    ... A ---- B ---- C ---- D  master
               \
                E ---- F  branch
```

### List of new commits on both branches (log with three dots):

<!-- more -->

```bash
git log master...branch

commit F
commit D
commit E
commit C

# With --left-right it shows additional markers for commits
git log --left-right master...branch
commit > F
commit < D
commit > E
commit < C
```

### Diff with two dots, `master` commits shown as removed changes, `branch` commits - as added:

```bash
git diff master..branch
-changes from C,D
+changes from E,F

# Same is without dots
git diff master branch
-changes from C,D
+changes from E,F
```

### Diff with two dots, `branch` commits are shown as removed changes, `master` commits as added:

```bash
git diff branch..master
+changes from C,D
-changes from E,F

# Same is without dots
git diff branch master
+changes from C,D
-changes from E,F
```

## Diff and log between two branches (only branch changes)

Often, we want to only see changes on the branch, without seeing what has changed on master (or on another base branch).

In this case, we can use `git log` with two dots to get the list of changes and `git log -p` to see the diff (while `git diff` with two dots will still show changes from the base branch, so is not suitable for this task).

For example, we have a history like this:

```
    ... A ---- B ---- C ---- D  master
               \
                E ---- F  branch
```

### List of new commits on `branch` (log with two dots):

```bash
git log master..branch
F
E
```

### List of new commits on `branch` (cherry):

```bash
git cherry master
+ F
+ E

git cherry -v master
+ F commit message
+ E commit message
```

The `git cherry` command provides a more compact output with the list of new commits on the `branch` comparing to `master`.

### List of new commits on `master` (log with two dots):

```bash
git log branch..master
D
C
```

### Diff, only new commits on `branch` (log with two dots and `-p` or diff with three dots):

```bash
git log -p master..branch
+changes from F
+changes from E

git diff master...branch
+changes from E
+changes from F
```

### Diff, only new commits on `master` (log with two dots and `-p` or diff with three dots):

```bash
git log -p branch..master
+changes from D
+changes from C

git diff branch...master
+changes from C
+changes from D
```

## Git diff and log inconsistency

In the sections above we can see that git diff and git log with three and two dots seem to behave inconsistently:

- `git log master..branch` - only new commits on `branch`
- `git diff master..branch` - changes on both `master` and `branch`
- `git log master...branch` - new commits on both `master` and `branch`
- `git diff master...branch` - only changes on `branch`

The [definition](https://git-scm.com/book/en/v2/Git-Tools-Revision-Selection#_commit_ranges) of two and three dots:

- Double Dot - range of commits that are reachable from one commit but aren’t reachable from another (in other words, new commits on branch that are not present on master)
- Triple-dot - all the commits that are reachable by either of two references but not by both of them (changes on both branches, but not common changes before that).

And `git log` does exactly that - new commits on the branch with two dots and all new commits on both branches with three dots.

While `git diff` works differently, here is a summary from the man page:

```
Comparing branches

        $ git diff topic master    (1)
        $ git diff topic..master   (2)
        $ git diff topic...master  (3)

    1. Changes between the tips of the topic and the master branches.
    2. Same as above.
    3. Changes that occurred on the master branch since when the topic branch was started off it.
```

This is why I like `git log -p` to show diffs instead of `git diff`.
It is more consistent and easier to remember - less dots (two) - less changes (only new changes on the branch), more dots (three) - more changes (changes on both branches):

- `git log master..branch` - only new commits on `branch`
- `git log -p master..branch` - only changes on `branch`
- `git log master...branch` - new commits on both `master` and `branch`
- `git log -p master...branch` - changes on both `master` and `branch`

## Diff staged changes

Show staged changes - added to index, but not committed yet:

```bash
git diff --cached
# or
git diff --staged
```

## Diff pulled changes

Show diff of changes pulled from upstream:

```bash
git pull origin
git diff @{1}..
```

Here `@` means `HEAD` and `@{1}` means "prior value of the HEAD", the list of prior values can be seen with `git reflog`.

## Log without merge commits

To show the log without merge commits use `--no-merges` flag:

```bash
git log --no-merges
```

## Log without another branch commits

To exclude commits on `master` (or another) branch, use `--not` flag:

```bash
git log contrib --not master # or git log contrib ^master
```

To exclude both commits on `master` commits and merge commits:

```bash
git log contrib ^master --no-merges
```

What was added in remote branch, but not in local:

```bash
git log origin/featureA ^featureA
```

Note: these three commands are equivalent:

```bash
git log refA..refB
git log ^refA refB
git log refB --not refA
```

Show all commits that are reachable from `refA` or `refB` but not from the `refC`:

```bash
git log refA refB ^refC
git log refA refB --not refC
```

## Git log formatting

Log with diff (p), only last two entries:

```bash
git log -p -2
```

One line log:

```bash
git log --pretty=oneline
```

Log with graph:

```bash
git log --pretty=format:"%h %s" --graph
```

Format log:

```bash
git log --pretty=format:"%h - %an, %ar : %s"
```

Log formatting options:

```
%H  Commit hash
%h  Abbreviated commit hash
%T  Tree hash
%t  Abbreviated tree hash
%P  Parent hashes
%p  Abbreviated parent hashes
%an Author name
%ae Author e-mail
%ad Author date (format respects the –date= option)
%ar Author date, relative
%cn Committer name
%ce Committer email
%cd Committer date
%cr Committer date, relative
%s  Subject
```

## Links

[Stackoverflow: How can I generate a git diff of what's changed since the last time I pulled?](http://stackoverflow.com/questions/61002/how-can-i-generate-a-git-diff-of-whats-changed-since-the-last-time-i-pulled)

[Stackoverflow: What are the differences between double-dot ".." and triple-dot "..." in Git diff commit ranges?](https://stackoverflow.com/questions/7251477/what-are-the-differences-between-double-dot-and-triple-dot-in-git-dif)

[ProGit: Git Tools - Revision Selectio](http://git-scm.com/book/en/Git-Tools-Revision-Selection)

[ProGit: Viewing Your Staged and Unstaged Changes](http://git-scm.com/book/en/Git-Basics-Recording-Changes-to-the-Repository#Viewing-Your-Staged-and-Unstaged-Changes)
