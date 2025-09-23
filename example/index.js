/**
 * Example app entry point.
 *
 * @remarks
 * Registers the example `App` component and logs whether the
 * environment is using Fabric (New Architecture) or Paper (Old Architecture).
 * This can help verify that the native view is running under the
 * expected architecture when testing the library.
 */
import { AppRegistry } from 'react-native';
import App from './src/App';
import { name as appName } from './app.json';

const uiManager = global?.nativeFabricUIManager ? 'Fabric/New Arch' : 'Paper/Old Arch';
console.log(`Using ${uiManager}`);

AppRegistry.registerComponent(appName, () => App);
