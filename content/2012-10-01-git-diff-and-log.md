---
date: 2012-10-01
tags: git
---
git - view changes - diff and log
===========================================

Diff staged changes
-------------------------------------------

```bash
    git diff --cached
    # or
    git diff --staged
```

Diff pulled changes
-------------------------------------------

```bash
    git pull origin
    git diff @{1}..
```

<!-- more -->
Diff two branches
-------------------------------------------

```bash
    ... A ---- B ---- C ---- D  master
               \
                E ---- F  test
```

We can use both `git diff` (to get differences) or `git log` (to get list of changes):

```bash
    git log/diff master..test
    F
    E

    git log/diff test..master
    D
    C

    git log/diff master...test
    D
    C
    F
    E

    git log --left-right master...test
    < D
    < C
    > F
    > E
```

Git log formatting
-------------------------------------------

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

```bash
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

Log without merges
-------------------------------------------

```bash
    git log --no-merges
```

Log - exclude other branch commits
-------------------------------------------
Exclude master commits:

```bash
    git log contrib --not master (or git log contrib ^master)
```

Exclude master commits and merges:

```bash
    git log contrib ^master --no-merges
```

What added in remote branch, but not in local:

```bash
    git log origin/featureA ^featureA
```

These three commands are equivalent:

```bash
    git log refA..refB
    git log ^refA refB
    git log refB --not refA
```

All commits that are reachable from refA or refB but not from refC:

```bash
    git log refA refB ^refC
    git log refA refB --not refC
```

Links
-------------------------------------------
[Stackoverflow: How can I generate a git diff of what's changed since the last time I pulled?](http://stackoverflow.com/questions/61002/how-can-i-generate-a-git-diff-of-whats-changed-since-the-last-time-i-pulled)

[ProGit: Git Tools - Revision Selectio](http://git-scm.com/book/en/Git-Tools-Revision-Selection)

[ProGit: Viewing Your Staged and Unstaged Changes](http://git-scm.com/book/en/Git-Basics-Recording-Changes-to-the-Repository#Viewing-Your-Staged-and-Unstaged-Changes)
