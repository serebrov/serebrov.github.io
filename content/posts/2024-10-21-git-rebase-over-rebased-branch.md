---
title: "git - how to rebase over a rebased branch, stacked branches"
date: 2024-10-21
tags: [git]
type: note
url: "/html/2024-10-21-git-rebase-over-rebased-branch.html"
---

It is often useful to split a large change into several smaller branches and create smaller PRs which are easier to understand and review.
This approach is also called "stacked branches" or "stacked pull requests".

The problem with this approach is that a modification of the earlier branch will require rebasing all branches created from it.

<!-- more -->

For example, we start with this state:

```
o---o---o---o  master
     \
      o---o---o  A
               \
                o - o B
```

And we do something like `git rebase -i HEAD~3` on branch `A` to change some commits:

```
o---o---o------------o  master
    \                  
     \--o---o---o new_A
      \                  
       o---o---o old_A   
                \
                 o - o B
```

Similar situation, we rebase branch A on top of `master`:

```
o---o---o--------------o  master
     \                  \
      o---o---o old_A    o---o---o new_A
               \
                o - o B
```

In both cases, we edited the branch `A` and it became `new_A`. Now we need to "move" branch `B` to have a root in `new_A` instead of `old_A`.

## Method 1: Rebase using `--update-refs` mode

This is a simpler, modern way to solve the problem. The `--update-refs` flag is available in Git 2.38 (October 2022) or later versions.

It can be used like this:

```
# Checkout the "top" branch in the stack
git checkout B

# Rebase on master: both branch A and B will be updated
git rebase -i master --update-refs
```

In this case, we started with this:

```
o---o---o---o  master
     \
      o---o---o  A
               \
                o - o B
```

And after the rebase we get this:

```
o---o---o---o  master
             \
              o---o---o  new A
                       \
                        o - o new B
```

Similarly, we can perform interactive rebase to edit the commit history:

```
# Checkout the "top" branch in the stack
git checkout B

# Interactive rebase: in this case the "HEAD~5" can cross branch points, affected branches will be updated automatically
git rebase -i HEAD~5 --update-refs
```

In both cases, `git` will update all affected branches and show the update result like this:

```
Successfully rebased and updated refs/heads/B.
Updated the following refs with --update-refs:
    refs/heads/A
    (if there are more branches, they will be listed here)  
```

Now we can push changes to the remote repository like this:

```
git push --force-with-lease origin B A # we can list all updated branches here
```

## Method 2: Rebase branches one-by-one

This is an older solution, before `--update-refs` was available.

We use `git rebase --onto` to rebase previous branches. It works like this:

```
# Checkout first branch
git checkout A

# Do something, edit commits
...

# Now we need to rebase later branches
git checkout B
git log # check how many commits we need to rebase

# Rebase (in this case we need to rebase 2 commits on branch B on top of new branch A)
git rebase --onto A B~2 B

# Or, the same, shorter
git rebase HEAD~2 --onto A
```

This method is also useful if we want to move an existing branch to another root.
For example, we decide that branch `B` does not depend on `A` and we want it to "grow" from master.

Start state:

```
o---o---o---o  master
     \
      o---o---o  A
               \
                o - o B
```

Desired state:

```
o---o---o---------------o  master
     \                   \
      o---o---o  A        o - o B    
```

This is how to do it:

```
git checkout B
git log # check how many commits we need to rebase

# Rebase (in this case we need to rebase 2 commits on branch B on top of master)
git rebase --onto master B~2 B

# Or, the same, shorter
git rebase HEAD~2 --onto master
```

## References

[git - How to rebase a branch off a rebased branch? - Stack Overflow](https://stackoverflow.com/questions/31881885/how-to-rebase-a-branch-off-a-rebased-branch)

[Working with stacked branches in Git is easier with --update-refs](https://andrewlock.net/working-with-stacked-branches-in-git-is-easier-with-update-refs/)
