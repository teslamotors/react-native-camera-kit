// @ts-check
import { platformIOS } from '@rock-js/platform-ios';
import { platformAndroid } from '@rock-js/platform-android';
import { pluginMetro } from '@rock-js/plugin-metro';
import { providerGitHub } from '@rock-js/provider-github';

/** @type {import('rock').Config} */
export default {
  bundler: pluginMetro(),
  platforms: {
    ios: platformIOS(),
    android: platformAndroid(),
  },
  remoteCacheProvider: providerGitHub({
    owner: 'teslamotors',
    repository: 'react-native-camera-kit',
    token: process.env.GITHUB_TOKEN,
  }),
};
