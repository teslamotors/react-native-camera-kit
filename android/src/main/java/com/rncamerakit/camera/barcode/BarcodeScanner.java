package com.rncamerakit.camera.barcode;


import android.graphics.Rect;
import android.hardware.Camera;
import android.os.Handler;
import android.os.Looper;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import android.util.Log;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.BinaryBitmap;
import com.google.zxing.DecodeHintType;
import com.google.zxing.LuminanceSource;
import com.google.zxing.MultiFormatReader;
import com.google.zxing.ReaderException;
import com.google.zxing.Result;
import com.google.zxing.common.HybridBinarizer;
import com.rncamerakit.camera.CameraViewManager;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;

public class BarcodeScanner {

    public interface ResultHandler {
        void handleResult(Result result);
    }

    private MultiFormatReader mMultiFormatReader;
    private static final List<BarcodeFormat> ALL_FORMATS = new ArrayList<>();
    private ResultHandler resultHandler;

    private Camera.PreviewCallback previewCallback;

    static {
        ALL_FORMATS.add(BarcodeFormat.AZTEC);
        ALL_FORMATS.add(BarcodeFormat.CODABAR);
        ALL_FORMATS.add(BarcodeFormat.CODE_39);
        ALL_FORMATS.add(BarcodeFormat.CODE_93);
        ALL_FORMATS.add(BarcodeFormat.CODE_128);
        ALL_FORMATS.add(BarcodeFormat.DATA_MATRIX);
        ALL_FORMATS.add(BarcodeFormat.EAN_8);
        ALL_FORMATS.add(BarcodeFormat.EAN_13);
        ALL_FORMATS.add(BarcodeFormat.ITF);
        ALL_FORMATS.add(BarcodeFormat.MAXICODE);
        ALL_FORMATS.add(BarcodeFormat.PDF_417);
        ALL_FORMATS.add(BarcodeFormat.QR_CODE);
        ALL_FORMATS.add(BarcodeFormat.RSS_14);
        ALL_FORMATS.add(BarcodeFormat.RSS_EXPANDED);
        ALL_FORMATS.add(BarcodeFormat.UPC_A);
        ALL_FORMATS.add(BarcodeFormat.UPC_E);
        ALL_FORMATS.add(BarcodeFormat.UPC_EAN_EXTENSION);
    }

    public BarcodeScanner(@NonNull Camera.PreviewCallback previewCallback, @NonNull ResultHandler resultHandler) {
        Map<DecodeHintType, Object> hints = new EnumMap<>(DecodeHintType.class);
        hints.put(DecodeHintType.POSSIBLE_FORMATS, ALL_FORMATS);
        mMultiFormatReader = new MultiFormatReader();
        mMultiFormatReader.setHints(hints);

        this.previewCallback = previewCallback;
        this.resultHandler = resultHandler;
    }

    public void onPreviewFrame(byte[] data, final Camera camera) {
        try {
            Camera.Size size = camera.getParameters().getPreviewSize();
            int width = size.width;
            int height = size.height;

            int tmp = width;
            width = height;
            height = tmp;
            data = getRotatedData(data, camera);

            final Result result = decodeResult(getLuminanceSource(data, width, height));

            if (result != null) {
                new Handler(Looper.getMainLooper()).post(new Runnable() {
                    @Override
                    public void run() {
                        resultHandler.handleResult(result);
                    }
                });
            }
            camera.setOneShotPreviewCallback(previewCallback);
        } catch (RuntimeException e) {
            Log.w("CameraKit", e.toString());
        }
    }

    @Nullable
    private Result decodeResult(LuminanceSource source) {
        Result rawResult = null;
        if (source != null) {
            BinaryBitmap bitmap = new BinaryBitmap(new HybridBinarizer(source));
            try {
                rawResult = mMultiFormatReader.decodeWithState(bitmap);
            } catch (ReaderException ignored) {
            } finally {
                mMultiFormatReader.reset();
            }

            if (rawResult == null && source.isRotateSupported()) {
                LuminanceSource rotatedSource = source.rotateCounterClockwise();
                bitmap = new BinaryBitmap(new HybridBinarizer(rotatedSource));
                try {
                    rawResult = mMultiFormatReader.decodeWithState(bitmap);
                } catch (ReaderException ignored) {
                } finally {
                    mMultiFormatReader.reset();
                }
            }
        }
        return rawResult;
    }

    private LuminanceSource getLuminanceSource(byte[] data, int width, int height) {
        Rect rect = CameraViewManager.getFramingRectInPreview(width, height);
        try {
            return new RotateLuminanceSource(data, width, height, rect.left, rect.top,
                    rect.width(), rect.height(), false);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private byte[] getRotatedData(byte[] data, Camera camera) {
        Camera.Size size = camera.getParameters().getPreviewSize();
        int width = size.width;
        int height = size.height;

        byte[] rotatedData = new byte[data.length];
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++)
                rotatedData[x * height + height - y - 1] = data[x + y * width];
        }
        return rotatedData;
    }
}
