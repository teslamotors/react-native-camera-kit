import React, { useState } from 'react';
import {
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
  AppState,
} from 'react-native';

import {
  PERMISSIONS,
  RESULTS,
  check,
  request,
} from 'react-native-permissions';

import BarcodeScreenExample from './BarcodeScreenExample';
import CameraExample from './CameraExample';

const photoPermission = Platform.OS === 'ios' ? PERMISSIONS.IOS.PHOTO_LIBRARY : PERMISSIONS.ANDROID.WRITE_EXTERNAL_STORAGE;
const cameraPermission = Platform.OS === 'ios' ? PERMISSIONS.IOS.CAMERA : PERMISSIONS.ANDROID.CAMERA;

const App = () => {
  const [example, setExample] = useState<JSX.Element>();

  const onBack = () => setExample(undefined);

  const [permissions, setPermissions] = React.useState({
    cam: false,
    photos: false,
  });

  // Update button states
  React.useEffect(() => {
    const refresh = async () => {
      const [cam, photos] = await Promise.all([
        check(cameraPermission),
        check(photoPermission),
      ]);
      setPermissions({
        cam: cam === RESULTS.GRANTED,
        photos: photos === RESULTS.GRANTED,
      });
    };

    const sub = AppState.addEventListener('change', state => {
      if (state === 'active') {
        refresh();
      }
    });

    refresh();

    return () => sub.remove();
  }, []);   

  const requestPermission = async (type, key) => {
    const res = await request(type);
    setPermissions(prev => ({...prev, [key]: res === RESULTS.GRANTED}));
  };

  if (example) {
    return example;
  }  

  return (
    <ScrollView style={{ flex: 1 }}>
      <View style={styles.headerContainer}>
        <Text style={{ fontSize: 60 }}>🎈</Text>
        <Text style={styles.headerText}>React Native Camera Kit</Text>
      </View>
      <View style={styles.container}>
        <TouchableOpacity
          style={[styles.button, permissions.cam ? styles.buttonPermission : styles.buttonNoPermission]}
          onPress={() => requestPermission(cameraPermission, 'cam')}
          color={permissions.cam ? 'green' : 'red'}
        >
          <Text style={styles.buttonText}>Camera</Text>
        </TouchableOpacity>
              
        <TouchableOpacity
          style={[styles.button, permissions.photos ? styles.buttonPermission : styles.buttonNoPermission]}
          onPress={() => requestPermission(photoPermission, 'photos')}
          color={permissions.photos ? 'green' : 'red'}
        >
          <Text style={styles.buttonText}>Photo Library</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.button} onPress={() => setExample(<CameraExample onBack={onBack} />)}>
          <Text style={styles.buttonText}>Camera</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.button} onPress={() => setExample(<BarcodeScreenExample onBack={onBack} />)}>
          <Text style={styles.buttonText}>Barcode Scanner</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

export default App;

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 30,
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
    paddingHorizontal: 24,
  },
  headerContainer: {
    flexDirection: 'column',
    backgroundColor: '#F5FCFF',
    justifyContent: 'center',
    alignItems: 'center',
    paddingTop: 100,
  },
  headerText: {
    color: 'black',
    fontSize: 24,
    fontWeight: 'bold',
  },
  button: {
    height: 60,
    borderRadius: 30,
    marginVertical: 12,
    width: '100%',
    backgroundColor: '#dddddd',
    justifyContent: 'center',
  },
  buttonText: {
    textAlign: 'center',
    fontSize: 20,
  },
  buttonNoPermission: {
    backgroundColor: 'deeppink',
  },
  buttonPermission: {
    backgroundColor: 'lightgreen'
  },
});
