---
title: "How to format large JSON file in command line"
date: 2023-06-11
tags: [json, cmd]
type: note
url: "/html/2023-06-11-format-json-command-line.html"
---

There are several tools that can be used to format a large JSON file.

Prettier (if you have node.js and npx installed):

```bash
npx run prettier input_json.json > formatted_json.json
```
 
With python:

```bash
cat input_json.json | python -m json.tool > formatted_json.json

# json.tool uses 4 spaces as indent by default, we can change it:
cat input_json.json | python -m json.tool --indent 2 > formatted_json.json
```

With [jq](https://jqlang.github.io/jq/):

```bash
jq '.' input_json.json > formatted_json.json
```

<!-- more -->

Reminder: to open a large file in vim / nvim it is better to run it with `-u NONE`: `nvim -u NONE formatted_json.json`.
