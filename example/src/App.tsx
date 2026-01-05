import React, { useState } from 'react';
import { StyleSheet, Text, View, TouchableOpacity, ScrollView, Button, Alert, TextInput } from 'react-native';

import BarcodeScreenExample from './BarcodeScreenExample';
import CameraExample from './CameraExample';

const App = () => {
  const [example, setExample] = useState<any>(undefined);
  const [testNo, setTestNo] = useState(0);
  const [interval, setIntervalId] = useState<number | null>(null);
  const [speed, setSpeed] = useState('1000');
  const onBack = () => setExample(undefined);

  if (example) {
    return example;
  }

  return (
    <ScrollView style={styles.scroll} scrollEnabled={false}>
      <View style={styles.container}>
        <Text style={{ fontSize: 60 }}>🎈</Text>
        <Text style={styles.headerText}>React Native Camera Kit</Text>
        <TouchableOpacity style={styles.button} onPress={() => setExample(<CameraExample onBack={onBack} />)}>
          <Text style={styles.buttonText}>Camera</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.button} onPress={() => setExample(<BarcodeScreenExample onBack={onBack} />)}>
          <Text style={styles.buttonText}>Barcode Scanner</Text>
        </TouchableOpacity>
        <View>
          <Text style={[styles.stressHeader, { marginTop: 12 }]}>Mount Stress Test</Text>
          <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            {!testNo ? (
              <>
                <View style={styles.inputContainer}>
                  <Text style={styles.inputLabel}>Speed (ms):</Text>
                  <TextInput
                    style={styles.input}
                    value={speed}
                    onChangeText={setSpeed}
                    keyboardType="number-pad"
                    placeholder="1000"
                    placeholderTextColor="#999"
                  />
                </View>

                <Button
                  title="Start"
                  onPress={() => {
                    Alert.alert(
                      '2 min or more',
                      'The mount stress test should run for at least 2 minutes on an iPhone 17 Pro before you can declare it a success. You need to press the stop button yourself.',
                      [
                        {
                          text: 'OK',
                          onPress: () => {
                            setIntervalId(
                              setInterval(() => {
                                setTestNo((prev) => {
                                  const newR = prev + 1;
                                  if (newR % 2 === 0) {
                                    setExample(<CameraExample key={String(Math.random())} stress onBack={onBack} />);
                                  } else {
                                    setExample(undefined);
                                  }
                                  return newR;
                                });
                              }, parseInt(speed, 10) || 1000),
                            );
                          },
                        },
                      ],
                    );
                  }}
                />
              </>
            ) : (
              <Button
                title="STOP STRESS TEST"
                onPress={() => {
                  setTestNo(0);
                  if (interval) {
                    clearInterval(interval);
                    setIntervalId(null);
                  }
                }}
              />
            )}
          </View>
        </View>
      </View>
    </ScrollView>
  );
};

export default App;

const styles = StyleSheet.create({
  scroll: {
    flexGrow: 1,
    backgroundColor: '#000000',
  },
  container: {
    flexGrow: 1,
    paddingTop: 100,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 24,
  },
  headerText: {
    color: 'white',
    fontSize: 24,
    fontWeight: 'bold',
    marginBlockEnd: 24,
  },
  stressHeader: {
    color: 'white',
    fontSize: 24,
    fontWeight: 'bold',
  },
  button: {
    height: 60,
    borderRadius: 30,
    marginVertical: 12,
    width: '100%',
    backgroundColor: '#666666',
    justifyContent: 'center',
  },
  buttonText: {
    color: 'white',
    textAlign: 'center',
    fontSize: 20,
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 12,
    minWidth: 170,
  },
  inputLabel: {
    color: 'white',
    fontSize: 16,
    marginRight: 12,
  },
  input: {
    flex: 1,
    height: 40,
    borderRadius: 8,
    backgroundColor: '#333',
    color: 'white',
    paddingHorizontal: 12,
    fontSize: 16,
  },
});
