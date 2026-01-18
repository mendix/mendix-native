const path = require('path');
const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');
const { withMetroConfig } = require('react-native-monorepo-config');

const root = path.resolve(__dirname, '..');

const customConfig = {
  resolver: {
    unstable_enablePackageExports: true,
  },
}; // Custom config can be removed once react native to update to higher version supporting package exports. https://github.com/callstackincubator/react-native-harness/issues/46#issuecomment-3718445067

const config = mergeConfig(getDefaultConfig(__dirname), customConfig);

/**
 * Metro configuration
 * https://facebook.github.io/metro/docs/configuration
 *
 * @type {import('metro-config').MetroConfig}
 */
module.exports = withMetroConfig(config, {
  root,
  dirname: __dirname,
  watchFolders: [root],
});
