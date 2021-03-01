import React, { Component } from 'react';
import { Alert } from 'react-native';
import CameraScreen from '../../src/CameraScreen';
import MaterialCommunityIcons from 'react-native-vector-icons/MaterialCommunityIcons';

const CameraScreenExampleWithCustomComponentAsIcon: React.FC<{}> = () => {
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
      cameraFlipImage={<MaterialCommunityIcons name="camera-switch-outline" size={26} color="white"/>}
      captureButtonImage={<MaterialCommunityIcons name="camera-iris" size={64} color="white"/>}
      flashData={{
        on: <MaterialCommunityIcons name="flash" size={26} color="white"/>,
        off: <MaterialCommunityIcons name="flash-off" size={26} color="white"/>,
        auto: <MaterialCommunityIcons name="flash-auto" size={26} color="white"/>,
      }}
      torchOnImage={<MaterialCommunityIcons name="flashlight" size={26} color="white" />}
      torchOffImage={<MaterialCommunityIcons name="flashlight-off" size={26} color="white" />}
      showCapturedImageCount
    />);
};

export default CameraScreenExampleWithCustomComponentAsIcon;
