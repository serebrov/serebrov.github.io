---
title: "Vue CLI Service Build Out of Memory Error"
date: 2024-04-05
tags: [vue]
type: note
url: "/html/2024-04-05-profile-vue-cli-service-build-out-of-memory.html"
---

# Solving the Vue app build out-of-memory error

If you encounter an out-of-memory error during the frontend build, you can increase the memory limit for the node process by setting the `NODE_OPTIONS` environment variable:

```bash
export NODE_OPTIONS=--max_old_space_size=8192
npm run build -- --mode production
```

Note that it should be enough to build the frontend application with the default memory limit. Increasing the limit is a temporary measure to be able to [profile and debug the build process](./2024-04-05-profile-vue-cli-service-build.html).

The error may look like this:

```
npm run build -- --mode production
...

⠹  Building for production...
<--- Last few GCs --->

[11515:0x7fb880040000]   161981 ms: Mark-sweep 4011.4 (4130.6) -> 3992.1 (4122.8) MB, 329.5 / 0.0 ms  (average mu = 0.206, current mu = 0.146) allocation failure; scavenge might not succeed
[11515:0x7fb880040000]   162358 ms: Mark-sweep 4009.6 (4134.1) -> 3994.4 (4125.5) MB, 332.5 / 0.0 ms  (average mu = 0.165, current mu = 0.119) allocation failure; scavenge might not succeed


<--- JS stacktrace --->

FATAL ERROR: Ineffective mark-compacts near heap limit Allocation failed - JavaScript heap out of memory
 1: 0x10372cc45 node::Abort() (.cold.1) [/Users/phn/.nvm/versions/node/v18.17.1/bin/node]
 2: ...
```
