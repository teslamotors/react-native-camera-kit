import { Dimensions } from 'react-native';
const { width, height } = Dimensions.get('window');

const styleObject = {
  cameraContainer: {
    position: 'absolute',
    top: 0,
    left: 0,
    width,
    height,
  },
  bottomButtons: {
    flex: 2,
    flexDirection: 'row',
    justifyContent: 'space-between',
    padding: 14,
  },
  gap: {
    flex: 10,
    flexDirection: 'column',
  },
};

export default styleObject;
