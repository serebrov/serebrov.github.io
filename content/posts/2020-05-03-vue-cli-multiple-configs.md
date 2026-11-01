---
title: 'Vue.js Cli: How to Use Multiple vue.config.js Configs'
date: 2020-05-02T21:00:00+00:00
tags:
- vue
type: note
url: "/html/2020-05-03-vue-cli-multiple-configs.html"

---
It can be useful to have more than one configuration file, for example, to build several code bundles.

<!-- more -->

The config file to use can be set with `VUE_CLI_SERVICE_CONFIG_PATH` environment variable:

```
# Build using vue.config.public.js
CONF=`realpath vue.config.public.js`
VUE_CLI_SERVICE_CONFIG_PATH=$CONF npm run build -- --mode production

# build using vue.config.js
npm run build -- --mode production
```

Where `npm run build` is defined in `package.json` as `vue-cli-service build`.

It is also possible to create several bundles using vue cli [multi-page mode](https://cli.vuejs.org/config/#pages), but in this case we will have big common js and css "vendors" package.

The js bundle is [solvable with custom chunks settings](https://stackoverflow.com/a/61089300/4612064), but it still leaves big css shared package (I didn't find the solution for that).

The separate vue.config.js file has the advantage of building a completely independent bundle.

The [alternative, check the comments](https://stackoverflow.com/a/50951316/4612064) is to have [separate configs and copy them over](https://gist.github.com/educkf/97e76da8d8c2b5dad17846a7d576e205), but this is less convenient than using the environment variable.

Note: I didn't find any mention on `VUE_CLI_SERVICE_CONFIG_PATH` in the documentation, found it looking at the [source code](https://github.com/vuejs/vue-cli/blob/a1041a897e4e9e57924bb6a2bfffde5db1d87ae7/packages/%40vue/cli-service/lib/Service.js#L323).
