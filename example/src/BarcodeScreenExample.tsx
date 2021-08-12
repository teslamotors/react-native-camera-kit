import React, { useState } from 'react';
import { Alert } from 'react-native';
import CameraScreen from '../../src/CameraScreen';
import CheckingScreen from './CheckingScreen';

interface IProps {}

const BarcodeScreenExample: React.FC<IProps> = ({}) => {
  const [value, setValue] = useState<string | undefined>(undefined);

  if (value) {
    return <CheckingScreen value={value} />;
  }

  const onBottomButtonPressed = (event) => {
    const captureImages = JSON.stringify(event.captureImages);
    Alert.alert(
      `"${event.type}" Button Pressed`,
      `${captureImages}`,
      [{ text: 'OK', onPress: () => console.log('OK Pressed') }],
      { cancelable: false },
    );
  };

  return (
    <CameraScreen
      actions={{ rightButtonText: 'Done', leftButtonText: 'Cancel' }}
      onBottomButtonPressed={onBottomButtonPressed}
      flashImages={{
        on: require('../images/flashOn.png'),
        off: require('../images/flashOff.png'),
        auto: require('../images/flashAuto.png'),
      }}
      scanBarcode
      showFrame
      laserColor="red"
      frameColor="white"
      onReadCode={setValue}
      hideControls
    />
  );
};

export default BarcodeScreenExample;
