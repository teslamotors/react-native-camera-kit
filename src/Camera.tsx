import { lazy } from 'react';
import { Platform } from 'react-native';

const Camera = lazy(() =>
  Platform.OS === 'ios'
    ? import('./Camera.ios')
    : import('./Camera.android'),
);

export default Camera;
