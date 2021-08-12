import React from 'react';
import { Image, TouchableOpacity, View } from 'react-native';
import { ITorchMode } from '..';
import { ITorchImageData } from '../CameraScreen';

interface IProps {
  torchMode: ITorchMode;
  data?: ITorchImageData;
  onPress: () => void;
}

const TorchButton: React.FC<IProps> = ({ data, torchMode, onPress }) => {
  if (!data) {
    return <></>;
  }

  const _component = data[torchMode];
  return (
    <TouchableOpacity style={{ paddingHorizontal: 15 }} onPress={onPress}>
      {React.isValidElement(_component) ? (
        <View style={{ flex: 1, justifyContent: 'center' }}>{_component}</View>
      ) : (
        <Image style={{ flex: 1, justifyContent: 'center' }} source={_component} resizeMode="contain" />
      )}
    </TouchableOpacity>
  );
};

export default TorchButton;
