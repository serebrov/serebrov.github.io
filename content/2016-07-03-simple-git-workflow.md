---
title: Simple Git Workflow
date: 2016-07-03
tags: git
type: post
---

The main purpose of this workflow is to have a reliable, but simple to use git workflow.
It is simple enough to be used by git beginners and minimizes possibility of mistakes (comparing to advanced flows which use rebase and related git features to achieve clean history).

The main idea of this workflow is that we create a new branch for every task and one developer works on this branch until the task is finished.
Once done, the work from the branch is merged back to the master branch.

<!-- more -->

Special branches are `master`, `staging` and `production`:

* `master` - integration branch, it is never modified directly, we only merge finished work from tasks branches
* `staging` - branch to test changes before we update production, it is never modified directly, only periodically updated from the `master` branch
* `production` - production state, it is never modified directly, only updated from the `staging` before we deploy new version to the production


```text
    ... o ---- o ---- o --- o - ... ----------------------- o ---- production
                                                           /
    ... o ---- o ---- o --- o - ... ----------- o - ... - o ------ staging
                                               /
    ... -- o -------------- o --------------- o --- ... ---------- master
           \               / \               /
            o ---- o ---- o   o --- o ----- o
            (task 1 branch)   (task 2 branch)
```

Task branches should be short-living, each task should take a few hours or, at maximum, a few days to complete.
So usually should be not necessary to merge updates back from master to the task branch.

General git guidelines:

* Always write meaningful commit messages, never leave them empty
* Commit often
* Give meaningful names to branches
* Always check `git` command output to make sure there are no errors

## The Simple Git Workflow

### 1) Select a Task to Work on

I assume that you have the task description in some project management like [Redmine](http://www.redmine.org/) or [Trello](https://trello.com/).

### 2) Check If Working Copy Is Clean

Check if there are no uncommited changes:

```bash
    $ git status

    On branch master
    Your branch is up-to-date with 'origin/some_branch'.
    nothing to commit, working directory clean
```

Note: if there are uncommited changes, you can try to go on with following steps; in the case when switching to another branch is not safe, git will stop with error message (you changes will not be lost). An alternative is to use the [git stash](https://git-scm.com/book/en/v1/Git-Tools-Stashing) command to temporary save your changes into the special `stash` area, you can restore these changes later with `git stash pop`.

### 3) Switch to the Master Branch and Update the Code

```bash
    $ git checkout master
    $ git pull

    remote: Counting objects: 1, done.
    remote: Total 1 (delta 0), reused 0 (delta 0), pack-reused 1
    Unpacking objects: 100% (1/1), done.
    From github.com:tapway/tapway-data
       f3ba979..68822fb  master     -> origin/master
    Updating f3ba979..68822fb
    Fast-forward
     docs/api.md | 5 +++++
     1 file changed, 5 insertions(+)
```

Note: It is not necessary to do `git checkout master` if you are already on `master`, but if you are a beginner, it is better to stick to the defined steps to avoid mistakes.

If there are no remote code changes, the output will look like this:

```bash
    $ git pull
    Already up-to-date.
```

### 4) Create the New Branch for the New Task

I prefer `XXXX-my-task-description` naming convention for branches, where `XXXX` is a task ID in the project management system and `my-task-description` is a short task definition.
For example, `1234-user-login` (a task to add user login page) or `2345-fix-facebook-signup` (a task to fix issue with Facebook sign-up).

```bash
    $ git checkout -b XXXX-my-task-description
```

Note: it is safe to create the new branch, even if you already have some changes.

Push the new branch to the server and track (-u) changes between local and remote branches:

```bash
    $ git push -u origin HEAD
```

### 5) Work on the Task

Do some changes, check the code state:

```bash
    $ git status
```

Add new / changed files, this will add all the changed and new files:

```
    $ git add .
```

To add only specific files, use `git add file_name.ext` command.

If there are some files you don't want to add under git control permanently, create or update the [.gitignore](https://git-scm.com/docs/gitignore) file and put file names or file patterns to ignore into it.

### 6) Commit Your Changes and Push to the Remote Repository

Check that changes are staged for commit:

```bash
    $ git status

    On branch my-task
    Your branch is up-to-date with 'origin/my-task'.
    Changes to be committed:
      (use "git reset HEAD <file>..." to unstage)

        new file:   content/2016-07-03-simple-git-workflow.md
        modified:   index.html
        modified:   sitemap.xml
```

Commit the changes:

```bash
    git commit -m "The description of the changes made"
```

At the moment you added your changes to the local repository.

Now push these changes to the remote repository:

```bash
    $ git push origin HEAD
```

### 7) Repeat Steps 5-6 as You Work on the Task

Do as many commits and pushes as you need while working on the task.

## How to Merge Finished Work to Master Branch with github.com

When the task is done, we need to merge it back to `master` branch.
This can be done using github `pull request` feature:

* Each feature is developed on the separate branch (as described above)
* Once branch is finished the developer creates pull request (in the github.com UI):
 * Make sure you committed and pushed all changes to github
 * Make sure the automatic tests suite (you really should have it) has passed successfully
 * Select the branch you work on (dropdown at the top)
 * Click the green `Compare, review, create a pull request` button (on the left of the branches dropdown)
 * Review changes and if everything looks ok click `Create pull request` button
 * Note: at this point changes are not merged yet. Now we have a pull request which can be reviewed by other developers and discussed. It is possible to update it with some fixes (just commit some changes on the same branch and push them)
* When the pull request is approved it can be merged to `master` branch:
 * Click `Merge pull requests` button and confirm merge
 * Note: github will not allow to merge the branch if there are conflicts. In this case you need to merge changes from master branch to you current branch, fix the conflicts and then push your branch to the server again.

Similar technique can be used not only with github, but with other git servers too (for example, bitbucket).

## How to Merge Finished Work to Master Branch Manually

Once the work is finished on the branch, the change can be reviewed manually.

1) Make sure the automatic tests suite has passed successfully on the branch, check that everything is commited and pushed:

```bash
    $ git status
```

2) Switch to the master branch and update it:

```bash
    $ git checkout master
    $ git pull
```

3) Merge the task branch

```bash
    $ git merge my-task-description
```

If there are conflicts between the task branch changes and master branch changes, git will show the notification and suggest to fix the conflicts.
I recommend using [kdiff3](http://kdiff3.sourceforge.net/) as a merge tool. Install it and run `git mergetool` to review and resolve conflicts.

4) Push changes to the server

```bash
    $ git push origin head
```

## How to Update staging / production Branches

The `staging` branch is a code state which is a candidate for next production update.
This branch is only updated from `master` branch:

```bash
   # checkout master and pull remote changes if any
   $ git checkout master
   $ git pull
   # checkout staging and pull remote changes if any
   $ git checkout staging
   $ git pull
   # merge master changes to staging
   $ git merge master
   $ git push origin HEAD
```

Once testing on the `staging` branch is done, it can be merged to the `production` branch:

```bash
   # checkout staging and pull remote changes if any
   $ git checkout staging
   $ git pull
   # checkout production and pull remote changes if any
   $ git checkout production
   $ git pull
   # merge staging changes to production
   $ git merge staging
   $ git push origin HEAD
```

## Alternative git Scenarios

### Work on the Branch Created by Someone Else

Note: while it is possible for several developers to work on the same branch at the same time, but it is better to avoid this and create separate branch for each developer.

So this is for the case when someone created the branch, but did not finish the work and passed the task to you.
This also can be useful to review other developer's work locally.

```bash
    # check current state, make sure everything is commited
    $ git status

    # get recent changes from the server
    $ git pull

    # check out and track remote branch created by someone else
    $ git checkout -t origin/the-branch-name

    # work on the branch as described in the main scenario
```

### Merge Changes from Another Branch

Sometimes you may need to merge code from some other branch.

For example to stay in sync with master branch or to get changes from some other branch which is not finished yet.

Usually it is better to avoid such merges because this makes your current branch history confusing.
It is not clear from the first sight what was done on the current branch and what was merged from other branches, so it complicates the code review once the work is finished.

Here we merge changes from `master` to our current task branch:

```bash
    # check current state, make sure everything is commited
    $ git status

    # check out the branch you want to merge from (for example, master)
    $ git checkout master
    # get recent changes from the server
    $ git pull

    # switch back to your branch
    $ git checkout my-branch-name
    # merge changes from master to your branch
    $ git merge master
```
