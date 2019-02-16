---
title: Managing NPM packages on github
date: 2019-02-16
tags: node.js, npm
type: note
---

Sometimes it is simpler to keep package on github, for example, if you have a fork of a published package with some private changes.
So you can avoid cluttering npm registry with similar packages, creating confusing for other people.

NPM [supports](https://docs.npmjs.com/cli/install) installing dependencies from github, but it is also good to have a versioning for your package so you can use it exactly as other packages, develop it independently and upgrade the dependency for the main project in a controlled way.

<!-- more -->

## Preparation

Add build branch to keep the last published version of the package:

```bash
git checkout -b build
git push -u origin HEAD
```

The build branch can include some files that are normally excluded from git control, for example, results of the webpack build.

## Workflow

The workflow I use is this:

- Do the changes as usually, create branches / Pull Requests, merge them to master
- Prepare release:
  - Checkout build branch: `git checkout build`
  - Merge master into it `git merge master`
  - Run commands to generate build (if any), like `npm run build`
  - Add build files to git: `git add buiid/.` and `git commit -m "Rebuild"`
  - Push changes: `git push origin HEAD`
  - Tag the new release `git tag 3.1.1 -a`, the `-a` flag means annotated tag, git will also ask for description
  - Add the list of changes to annotation (I mostly use titles of pull requests along with PR id, like "Fix search, #19", the PR id will turn into a link in github UI
  - Push the tags: `git push origin --tags`

Note: don't forget about [semver](https://docs.npmjs.com/about-semantic-versioning), basically: increase last number for fixes, second for new features, first for breaking changes.

Now, the new release will appear under "releases", for example [https://github.com/serebrov/emoji-mart-vue/releases](https://github.com/serebrov/emoji-mart-vue/releases).

## Use the Package

Include package from github, in `package.json`:

```
  "dependencies": {
    "emoji-mart-vue": "github:serebrov/emoji-mart-vue#3.1.1",
  }
```

Note that we specify the tag (`#3.1.1` in the example above), so we can work on the package and release new versions (create new tags) and update the package version used by the main project when we want / need that.
