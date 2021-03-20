import React from 'react';
import { Alert } from 'react-native';
import CameraScreen from '../../src/CameraScreen';

const CameraScreenExample: React.FC<{}> = () => {
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
      onBottomButtonPressed={(event) => onBottomButtonPressed(event)}
      flashData={{
        on: require('../images/flashOn.png'),
        off: require('../images/flashOff.png'),
        auto: require('../images/flashAuto.png'),
      }}
      cameraFlipImage={require('../images/cameraFlipIcon.png')}
      captureButtonImage={require('../images/cameraButton.png')}
      torchOnImage={require('../images/torchOn.png')}
      torchOffImage={require('../images/torchOff.png')}
      showCapturedImageCount
    />
  );
};

export default CameraScreenExample;
