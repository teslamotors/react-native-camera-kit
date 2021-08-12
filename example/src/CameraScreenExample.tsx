import React from 'react';
import { Alert } from 'react-native';
import CameraScreen from '../../src/CameraScreen';
import media from './media';

interface IProps {}

const CameraScreenExample: React.FC<IProps> = () => {
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
      cameraFlipImage={media.images.flip}
      captureButtonImage={media.images.camera}
      torchImages={{
        on: media.images.torch.on,
        off: media.images.torch.off,
      }}
      showCapturedImageCount
      flashImages={media.images.flash}
    />
  );
};

export default CameraScreenExample;
