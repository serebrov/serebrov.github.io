---
title: "bash - how to run command in a loop until it fails"
date: 2023-07-20
tags: [bash]
type: note
url: "/html/2023-07-20-bash-how-to-run-command-until-it-fails.html"
---

I want to debug a flaky test and run it multiple times until the test runner returns non-zero code.

Here is how to do that with a one-liner:

```bash
# Put the command to run into a variable, for convenience
CMD="npm run test:unit -- tests/unit/MyTest.spec.ts -t \"'my test case'\""
# Run it multiple times until it fails
cnt=1; while eval $CMD; do echo "Command succeeded, attempt $cnt"; ((cnt++)); done
```

<!-- more -->

Alternatively, create a script to run the command, it might be more useful if there is a sequence of commands to run:

```bash
#!/bin/bash

while true; do
  # Replace with your command
  npm run test:unit -- tests/unit/MyTest.spec.ts -t \"'my test case'\""
  exit_code=$?

  if [ $exit_code -ne 0 ]; then
    echo "Command failed with exit code $exit_code, stopping..."
    break
  fi
done
```
