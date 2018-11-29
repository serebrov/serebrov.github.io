---
title: Debugging Python With ipdb and pdbpp
date: 2018-11-28
tags: python
type: note
---

To get a very convenient full-screen console debugger for python, install `ipdb` and `pdbpp` packages.

Then use `__import__('ipdb').set_trace()` to start the debugger and enter `sticky` to switch to the full-screen mode.

<!-- more -->

Both packages can be installed with pip:

```
virtualenv -p python3 venv
source venv/bin/activate

pip install ipdb
pip install pdbpp
```

The `ipdb` package improves the standard (pdb) debugger by adding syntax highlight and code completion.
And the `pdbpp` adds the "sticky" mode, so the debugger can be run in a full-screen mode, in terminal:

![debugger demo](/content/2018-11-28-python-degugging.gif)

This way we get an interactive debugging environment where we can execute the code, inspect variables and experiment with the live application state.

It works well for command-line scripts and web applications, the only thing you need is to start the application from terminal in a non-daemon mode, so the debugger can break the execution and switch to the interactive mode.

It also works if the app is started inside the docker container (same here - run in foreground mode, "docker run ..." or "docker-compose run ..." without `-d` flag).
