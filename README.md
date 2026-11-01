[Development notes serebrov.github.io](https://serebrov.github.io)

# How it Works

Content is stored under [./content/posts](./content/posts) folder.

[Hugo](https://gohugo.io/) builds the content and puts results into the [./public](./public) submodule, that points to a repository with public files, [serebrov.github.io](https://github.com/serebrov/serebrov.github.io).

The public files repository is served via [Git pages](https://pages.github.com/) at https://serebrov.github.io.

# Building manually

- Add new post / change content
- git add, git commit
- Run `./deploy.sh`

# Possible issues

The page does not get rendered if the `date` in the frontmatter is in the incorrect format or in the future.

It is possible to build pages with future date using the flag `hugo --buildFuture` (but in my case it was just a mistake, I used 2023-11 instead of 2023-10 and was wondering why the page does not get built).

# Automated Setup

The build is automated using [github actions](https://docs.github.com/en/actions). When we edit/add files in the `content` folder locally or directly on Github, the live site is updated automatically.

The worflow implementation is in the [`.github/workflows/hugo.yaml`](./.github/./.github/workflows/hugo.yaml).

First, we checkout the repository and specify the `token` parameter for the [`actions/checkout@v3`](https://github.com/actions/checkout).

We need the token as build process commits to both this and [public files repository](https://github.com/serebrov/serebrov.github.io/commits/master).

Note: The token has expiration time, can be created here: https://github.com/settings/tokens. And then added in the current repository "Settings - Secrets and variables - actions".

```yaml
- name: Checkout
  uses: actions/checkout@v3
  with:
    submodules: recursive
    fetch-depth: 0
    token: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
```

Configure git:

```yaml
- name: Configure git
  run: |
    git config --global user.name 'Borys Serebrov'
    git config --global user.email 'serebrov@users.noreply.github.com'
```

In the submodule directory (`working-directory: ./public`), switch to `master` branch (it should be the same commit, but the submodule initially in the detached HEAD state, not on the branch):

```yaml
- name: Prepare the submodule
  working-directory: ./public
  run: |
    git checkout master
```

Rebuild the content by running `hugo`:

```yaml
- name: Build with Hugo
  run: hugo --gc --minified
```

In the submodule directory: add all changes, commit and push to the parent repository:

```yaml
- name: Commit public files
  working-directory: ./public
  run: |
    git checkout master
    git add .
    msg="rebuilding site $(date)" && git commit -m "$msg" && git push origin master
```

Now update the `public` submodule reference in this repository, commit and push:

```yaml
- name: Commit public submodule ref
  run: |
    git add .
    msg="[ci skip] update public ref $(date)" && git commit -m "$msg"
    git push origin master
```

The rest is done by Github pages, when new commit is pushed to the [serebrov.github.io](https://github.com/serebrov/serebrov.github.io) (the `public` submodule), the live site is updated automatically.
