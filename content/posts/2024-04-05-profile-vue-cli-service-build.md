---
title: "Profile Vue CLI Service Build (actually webpack build)"
date: 2024-04-05
tags: [vue]
type: note
url: "/html/2024-04-05-profile-vue-cli-service-build.html"
---

# How to Profile Vue CLI Service Build (webpack build)

The vue cli build is managed by the `build` command of the `@vue/cli-service` package. The command is located in `node_modules/@vue/cli-service/lib/commands/build/index.js`.

Looking into [the code](https://github.com/vuejs/vue-cli/blob/f0f254e4bc81ed322eeb9f7de346e987e845068e/packages/%40vue/cli-service/lib/commands/build/index.js#L199), there is not too much to debug or profile here, it boils down to this:

```javascript
  // Compose the webpackConfig object
  // ...
  // Run webpack:
  return new Promise((resolve, reject) => {
    webpack(webpackConfig, (err, stats) => {
            ...
    })
  })
```

So the actual problem is webpack build profiling. There are some tools that can help with it:

* [progress-plugin](https://webpack.js.org/plugins/progress-plugin/)
* [profiling-plugin](https://webpack.js.org/plugins/profiling-plugin/)
* [speed-measure-webpack-plugin](https://github.com/stephencookdev/speed-measure-webpack-plugin)

To enable these plugins, modify the `vue.config.js` file approximately like this:

```javascript
// vue.config.js

let configureWebpack = {
  devtool: 'source-map',
  plugins: [
    ... // plugins you may use for regular build are here
  ],
}

if (process.env.PROFILE_BUILD === 'true') {
  console.log('PROFILE_BUILD enabled')

  // Add progress report plugin and profiler.
  const handler = (percentage, message, ...args) => {
    // Output each progress message directly to the console:
    console.info(percentage, message, ...args);
  };
  const debugPlugins = [
    new webpack.ProgressPlugin(handler),
    new webpack.debug.ProfilingPlugin()
  ];
  configureWebpack.plugins = debugPlugins.concat(configureWebpack.plugins);

  // Add speed measure plugin, see
  // https://github.com/stephencookdev/speed-measure-webpack-plugin
  const SpeedMeasurePlugin = require("speed-measure-webpack-plugin");
  const smp = new SpeedMeasurePlugin();
  configureWebpack = smp.wrap(configureWebpack);
}

const config = {
    publicPath: '/',
    ... // other vue config parameters
    configureWebpack: configureWebpack,
}

module.exports = config
```

Then do something like `PROFILE_BUILD=true npm run build` to profile the build.

The build process will log extra information about the build time and the time spent in each plugin on the screen and will also generate the `events.json` file in the `frontend` folder.

In order to view the profile file created by `profiling-plugin`, you can use Chrome DevTools:
- Run build process as above, with profiling enabled, it should generate the `events.json` file.
- Go to Chrome, open DevTools, and go to the Performance tab (formerly Timeline).
- Drag and drop generated `events.json` file into the profiler.

To learn even more about the build, also generate the bundle analyzer report with the Vue Cli [Webpack Bundle Analyzer](https://www.npmjs.com/package/vue-cli-plugin-webpack-bundle-analyzer) plugin. Add the following to the `vue.config.js`:

```
// vue.config.js

  const config = {
    publicPath: '/',
    ...
    configureWebpack: configureWebpack,
    ...
    pluginOptions: {
      // Webpack Bundle Analyzer
      // Visualize size of webpack output files with an interactive zoomable treemap.
      // Report file will be generated automatically during build and saved to `reportFilename` file
      webpackBundleAnalyzer: {
        reportFilename: 'webpack-bundle-analyzer-report.html',
        openAnalyzer: false,
      },
    },
  }
  module.exports = config
```
