import { __awaiter } from "tslib";
import React from 'react';
import _update from 'lodash/update';
import _cloneDeep from 'lodash/cloneDeep';
import { requireNativeComponent, findNodeHandle, NativeModules, processColor } from 'react-native';
const { RNCameraKitModule } = NativeModules;
const NativeCamera = requireNativeComponent('CKCameraManager');
const Camera = React.forwardRef((props, ref) => {
    const nativeRef = React.useRef();
    React.useImperativeHandle(ref, () => ({
        capture: (options = {}) => __awaiter(void 0, void 0, void 0, function* () {
            var _a;
            return yield RNCameraKitModule.capture(options, findNodeHandle((_a = nativeRef.current) !== null && _a !== void 0 ? _a : null));
        }),
        requestDeviceCameraAuthorization: () => {
            throw new Error('Not implemented');
        },
        checkDeviceCameraAuthorizationStatus: () => {
            throw new Error('Not implemented');
        },
    }));
    const transformedProps = _cloneDeep(props);
    _update(transformedProps, 'cameraOptions.ratioOverlayColor', (c) => processColor(c));
    _update(transformedProps, 'frameColor', (c) => processColor(c));
    _update(transformedProps, 'laserColor', (c) => processColor(c));
    _update(transformedProps, 'surfaceColor', (c) => processColor(c));
    return (<NativeCamera style={{ minWidth: 100, minHeight: 100 }} flashMode={props.flashMode} ref={nativeRef} {...transformedProps}/>);
});
export default Camera;
//# sourceMappingURL=Camera.android.js.map