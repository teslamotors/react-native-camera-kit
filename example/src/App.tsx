import React from 'react';
import {
  FlatList, StyleSheet,
  Text,

  TouchableOpacity, View,
} from 'react-native';
import CameraScreen from '../../src/CameraScreen';
import BarcodeScreenExample from './BarcodeScreenExample';
import CameraExample from './CameraExample';
import CameraScreenExample from './CameraScreenExample';

const CustomCamera: React.FC<{}> = () => (
  <CameraScreen
    actions={{ rightButtonText: 'Done', leftButtonText: 'Cancel' }}
    cameraFlipImage={<Text style={styles.customText}>Flip</Text>}
    captureButtonImage={<Text  style={styles.customText}>Capture</Text>}
    flashData={{
      on: <Text style={styles.customText}>Flash: ON</Text>,
      off: <Text style={styles.customText}>Flash: OFF</Text>,
      auto: <Text style={styles.customText}>Flash: AUTO</Text>,
    }}
    torchOnImage={<Text style={styles.customText}>Torch: ON</Text>}
    torchOffImage={<Text style={styles.customText}>Torch: OFF</Text>}
    showCapturedImageCount
  />
);

const listItems = [
  {
    title: 'Camera',
    component: () => CameraExample,
  },
  {
    title: 'Camera Screen',
    component: () => CameraScreenExample,
  },
  {
    title: 'Barcode Scanner',
    component: () => BarcodeScreenExample,
  },
  {
    title: 'Camera with Custom Components',
    component: () => CustomCamera,
  },
];

const App: React.FC<{}> = () => {
  const [example, setExample] = React.useState<any>(undefined);

  if (example) {
    const Example = example;
    return <Example />;
  }

  return (
    <View style={{ flex: 1 }}>
      <View style={styles.headerContainer}>
        <Text style={{ fontSize: 60 }}>🎈</Text>
        <Text style={styles.headerText}>
            React Native Camera Kit
        </Text>
      </View>
      <View style={styles.container}>
        <FlatList
          data={listItems}
          keyExtractor={(item, index) => `${item.title}_${index}`}
          renderItem={({item}) => (<TouchableOpacity style={styles.button} onPress={() => setExample(item.component)}>
            <Text style={styles.buttonText}>
              {item.title}
            </Text>
          </TouchableOpacity>)}
        />
        {/*<TouchableOpacity style={styles.button} onPress={() => setExample(CameraExample)}>
          <Text style={styles.buttonText}>
              Camera
          </Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.button} onPress={() => setExample(CameraScreenExample)}>
          <Text style={styles.buttonText}>
              Camera Screen
          </Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.button} onPress={() => setExample(BarcodeScreenExample)}>
          <Text style={styles.buttonText}>
              Barcode Scanner
          </Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.button}
          onPress={() => setExample(InlineExample)}
        >
          <Text style={styles.buttonText}>
              Camera Screen with custom icons
          </Text>
        </TouchableOpacity>*/}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 30,
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
    marginHorizontal: 24,
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
  customText: {
    color: 'white',
  },
});

export default App;
