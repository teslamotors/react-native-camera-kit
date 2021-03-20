import React from 'react';
import { Alert } from 'react-native';
import CameraScreen from '../../src/CameraScreen';
import CheckingScreen from './CheckingScreen';

const BarcodeScreenExample: React.FC<{value?: any}> = (props) => {
  const [example, setExample] = React.useState<any>(undefined);
  const [valueState, setValueState] = React.useState<any>(undefined);

  const onBottomButtonPressed = (event) => {
    const captureImages = JSON.stringify(event.captureImages);
    Alert.alert(
      `"${event.type}" Button Pressed`,
      `${captureImages}`,
      [{ text: 'OK', onPress: () => console.log('OK Pressed') }],
      { cancelable: false },
    );
  };

  if (example) {
    const Screen = example;
    return <Screen value={valueState} />;
  }


  return (
    <CameraScreen
      actions={{ rightButtonText: 'Done', leftButtonText: 'Cancel' }}
      onBottomButtonPressed={(event) => onBottomButtonPressed(event)}
      flashData={{
        on: require('../images/flashOn.png'),
        off: require('../images/flashOff.png'),
        auto: require('../images/flashAuto.png'),
      }}
      scanBarcode
      showFrame
      laserColor="red"
      frameColor="white"
      onReadCode={(event) => {
        setExample(CheckingScreen);
        setValueState(event.codeStringValue);
      }}
      hideControls
    />
  );
};

export default BarcodeScreenExample;
