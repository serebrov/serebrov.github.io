---
title: Git Hook to Add Issue Number to Commit Message
date: 2019-06-16
tags: git
type: note
---

When using project management system (Jira, Redmine, Github issues, etc) it is useful to add the issue number into commit message that makes is easier to understand which issue the commit belongs to and often allows the project management system to display related commits.

For same reasons, it is also useful to include the issue number into branch name, such as `123-branch-description` or `feature/PROJECT-123-branch-description`.

<!-- more -->

The process of adding the issue number into commit message can be automated with git `prepare-commit-msg` hook (shell script).

Below are few examples of hook scripts.

## Branch Named as `123-branch-description`

In the simplest case we have branches named as `123-branch-description`, where `123` is the issue id:

```
#!/bin/bash

# This hook works for branches named such as "123-description" and will add "[#123]" to the commit message.

# get current branch
branchName=`git rev-parse --abbrev-ref HEAD`

# search issue id in the branch name, such a "123-description" or "XXX-123-description"
issueId=$(echo $branchName | sed -nE 's,([A-Z]?-?[0-9]+)-.+,\1,p')

# only prepare commit message if pattern matched and issue id was found
if [[ ! -z $issueId ]]; then
 # $1 is the name of the file containing the commit message
 # sed -i.bak -e "1s/^/\n\n[$issueId]\n/" $1
 echo -e "[#$issueId] ""$(cat $1)" > "$1"
 # echo -e "[$issueId]\n""$(cat $1)" > "$1"
 # sed -i.bak -e "1s/^/$TRIMMED /" $1
fi
```

## Branch Named as `feature/PROJECT-123-branch-description`

This version is useful for gitflow and Jira (where we should use PROJECT-123 format to display commits in the issue):

```
#!/bin/bash

# This hook works for branches named such as "feature/ABC-123-description" and will add "[ABC-123]" to the commit message.

# get current branch
branchName=`git rev-parse --abbrev-ref HEAD`

# search jira issue id in a pattern such a "feature/ABC-123-description"
jiraId=$(echo $branchName | sed -nE 's,[a-z]+/([A-Z]+-[0-9]+)-.+,\1,p')

# only prepare commit message if pattern matched and jiraId was found
if [[ ! -z $jiraId ]]; then
 # $1 is the name of the file containing the commit message
 # sed -i.bak -e "1s/^/\n\n[$jiraId]\n/" $1
 echo -e "[$jiraId] ""$(cat $1)" > "$1"
 # echo -e "[$jiraId]\n""$(cat $1)" > "$1"
 # sed -i.bak -e "1s/^/$TRIMMED /" $1
fi
```

## Cross-Repository Version

This is useful when project uses multiple repositories on GitHub and issues tracked in one of the project (or there is a separate project for issues).

In this case, we aslo need to add full repository name to the commit message.

The hook below puts short issue number at the beginning of the commit message and adds full issue id (`organization/repository/#issueId`) at the end.

```
#!/bin/bash

# This hook works for branches named such as "123-description" and will add "[#123]" to the commit message.

# get current branch
branchName=`git rev-parse --abbrev-ref HEAD`

# search issue id in the branch name, such a "123-description" or "XXX-123-description"
issueId=$(echo $branchName | sed -nE 's,([A-Z]?-?[0-9]+)-.+,\1,p')

# only prepare commit message if pattern matched and issue id was found
if [[ ! -z $issueId ]]; then
 # $1 is the name of the file containing the commit message
 # We prepend issue number in the beginning (so we can easily see it in history)
 # And also we append the full issue id (with organization/repository#) prefix,
 # so this commit hook works for other repositories (frontend) too.
 echo -e "[#$issueId] ""$(cat $1)""\n[organization/repository#$issueId]" > "$1"
 # sed -i.bak -e "1s/^/\n\n[$issueId]\n/" $1
 # echo -e "[$issueId]\n""$(cat $1)" > "$1"
 # sed -i.bak -e "1s/^/$TRIMMED /" $1
fi
```

## Installing the Hook

- Create the `.git/hooks/prepare-commit-msg` script
- Copy the content from the snippet above
- Make the file executable `chmod +x .git/hooks/prepare-commit-msg`
- Try to commit something, check that the issue number is automatically added

Note: when you do the `commit --amend`, the issue number will be added for the second time - you need to remove it manually.
