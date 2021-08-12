import React, { useMemo } from 'react';
import { Image, StyleSheet, TouchableOpacity, View } from 'react-native';
import { IFlashImageData } from '../CameraScreen';

interface IProps {
  index: number;
  flashImages: IFlashImageData;
  onPress: () => void;
}

const FlashButton: React.FC<IProps> = ({ index, flashImages, onPress }) => {
  const component = useMemo(() => {
    let _result;
    switch (index) {
      case 0:
        _result = flashImages.auto;
      case 1:
        _result = flashImages.on;
      default:
        _result = flashImages.off;
    }
    return _result;
  }, [flashImages.auto, flashImages.off, flashImages.on, index]);

  return (
    <TouchableOpacity style={{ paddingHorizontal: 15 }} onPress={onPress}>
      {React.isValidElement(component) ? (
        <View style={styles.view}>{component}</View>
      ) : (
        <Image style={styles.image} source={component} resizeMode="contain" />
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

export default FlashButton;
