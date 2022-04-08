import React, { useState } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  useWindowDimensions,
  SafeAreaView,
  ScrollView,
} from 'react-native';

import CameraScreenExample from './CameraScreenExample';
import BarcodeScreenExample from './BarcodeScreenExample';
import CameraExample from './CameraExample';

const isOrientationPortrait = (width: number, height: number) => height >= width;

type SimpleContainerProps = {
  children: any;
  goHome: () => void;
};
function SimpleContainer(props: SimpleContainerProps) {
  const { height, width } = useWindowDimensions();
  const isPortrait = isOrientationPortrait(width, height);
  const orientation: string = isPortrait ? 'portrait' : 'landscape';
  const tipText = `width:${width},height:${height},orientation:${orientation}`;
  return (
    <SafeAreaView style={styles.flex1}>
      <View style={styles.flex1}>
        <View style={[styles.flexDirectionRow, styles.bgCCC]}>
          <TouchableOpacity onPress={props.goHome} style={styles.marginRight20}>
            <Text style={{ color: 'blue' }}>Go Home</Text>
          </TouchableOpacity>
          <Text>{tipText}</Text>
        </View>
        <View style={[styles.flex1, styles.border1red]}>{props.children}</View>
      </View>
    </SafeAreaView>
  );
}

type AppState = {
  example: Function | null;
};
export default function App() {
  const [state, setState] = useState<AppState>({ example: null });
  const goHome = () => setState({ example: null });
  if (state.example) {
    const Example: any = state.example;
    return (
      <SimpleContainer goHome={goHome}>
        <Example />
      </SimpleContainer>
    );
  } else {
    return (
      <SimpleContainer goHome={goHome}>
        <ScrollView style={{ flex: 1 }}>
          <View style={styles.headerContainer}>
            <Text style={{ fontSize: 60 }}>🎈</Text>
            <Text style={styles.headerText}>React Native Camera Kit</Text>
          </View>
          <View style={styles.container}>
            <TouchableOpacity style={styles.button} onPress={() => setState({ example: CameraExample })}>
              <Text style={styles.buttonText}>Camera</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.button} onPress={() => setState({ example: CameraScreenExample })}>
              <Text style={styles.buttonText}>Camera Screen</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.button} onPress={() => setState({ example: BarcodeScreenExample })}>
              <Text style={styles.buttonText}>Barcode Scanner</Text>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </SimpleContainer>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 30,
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
    backgroundColor: '#dddddd',
    justifyContent: 'center',
  },
  buttonText: {
    textAlign: 'center',
    fontSize: 20,
  },
  flexDirectionRow: {
    flexDirection: 'row',
  },
  bgCCC: {
    backgroundColor: '#ccc',
  },
  flex1: { flex: 1 },
  border1red: {
    borderWidth: 1,
    borderColor: 'red',
  },
  marginRight20: {
    marginRight: 20,
  },
});
