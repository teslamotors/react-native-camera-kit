const exec = require('shell-utils').exec;

function removeHardlinks() {
  exec.execSync(`hardlink ./node_modules/react-native-camera-kit/ -u || true`);
}

function removeNodeModules() {
  exec.execSync(`rm -rf ./node_modules || true`);
}

function copyNodeModules() {
  exec.execSync(`cp -Rf ../node_modules ./`);
}

function installMain() {
  exec.execSync(`mkdir -p ./node_modules/react-native-camera-kit`);
  const tar = exec.execSyncRead(`cd .. && npm pack`);
  exec.execSync(`tar -xf ../${tar} -C ./node_modules/react-native-camera-kit --strip 1`);
  exec.execSync(`rm ../${tar}`);
}

function hardlink() {
  exec.execSync(`hardlink ../ ./node_modules/react-native-camera-kit || true`);
}

function run() {
  removeHardlinks();
  removeNodeModules();
  copyNodeModules();
  installMain();
  hardlink();
}

run();
