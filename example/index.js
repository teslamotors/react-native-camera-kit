import { AppRegistry } from 'react-native';
import App from './src/App';
import { name as appName } from './app.json';

const uiManager = global?.nativeFabricUIManager ? 'Fabric/New Arch' : 'Paper/Old Arch';
console.log(`Using ${uiManager}`);

AppRegistry.registerComponent(appName, () => App);
