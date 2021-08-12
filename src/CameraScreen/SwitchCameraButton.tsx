import React from 'react';
import { Image, StyleSheet, TouchableOpacity, View } from 'react-native';
import { IIconType } from '../CameraScreen';

interface IProps {
  cameraFlipImage?: IIconType;
  onPress: () => void;
}

const SwitchCameraButton: React.FC<IProps> = ({ cameraFlipImage, onPress }) => {
  if (!cameraFlipImage) return <></>;
  return (
    <TouchableOpacity style={{ paddingHorizontal: 15 }} onPress={onPress}>
      {React.isValidElement(cameraFlipImage) ? (
        <View style={styles.view}>{cameraFlipImage}</View>
      ) : (
        <Image style={styles.image} source={cameraFlipImage} resizeMode="contain" />
      )}
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  view: {
    flex: 1,
    justifyContent: 'center',
  },
  image: {
    flex: 1,
    justifyContent: 'center',
  },
});

export default SwitchCameraButton;
