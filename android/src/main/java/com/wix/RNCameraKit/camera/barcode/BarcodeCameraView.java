package com.wix.RNCameraKit.camera.barcode;


import android.content.Context;
import android.util.AttributeSet;
import android.util.Log;

import com.facebook.react.bridge.Promise;
import com.google.zxing.Result;

import me.dm7.barcodescanner.zxing.ZXingScannerView;

public class BarcodeCameraView extends ZXingScannerView {

    public BarcodeCameraView(Context context) {
        super(context);
    }

    public BarcodeCameraView(Context context, AttributeSet attributeSet) {
        super(context, attributeSet);
    }

    private final Runnable measureAndLayout = new Runnable() {
        @Override
        public void run() {
            measure(
                    MeasureSpec.makeMeasureSpec(getWidth(), MeasureSpec.EXACTLY),
                    MeasureSpec.makeMeasureSpec(getHeight(), MeasureSpec.EXACTLY));
            layout(getLeft(), getTop(), getRight(), getBottom());
        }
    };

    @Override
    public void requestLayout() {
        super.requestLayout();
        post(measureAndLayout);
    }

    public void setHandler(final Promise promise) {
        setResultHandler(new ResultHandler() {
            @Override
            public void handleResult(Result result) {
                String resultStr = result.getText();
                Log.i("NIGA", "result = " + resultStr);
                if (promise != null) {
                    promise.resolve(resultStr);
                }
            }
        });
    }
}
