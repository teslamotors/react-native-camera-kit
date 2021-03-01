import { Platform } from 'react-native';

export default Platform.select({
  android: () => require('./AndroidCamera'),
  ios: () => require('./IOSCamera'),
  default: () => null,
})();
