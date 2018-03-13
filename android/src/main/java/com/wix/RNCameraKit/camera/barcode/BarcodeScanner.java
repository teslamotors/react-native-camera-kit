package com.wix.RNCameraKit.camera.barcode;


import android.content.Context;
import android.content.res.Configuration;
import android.graphics.Rect;
import android.hardware.Camera;
import android.os.Handler;
import android.os.Looper;
import android.util.AttributeSet;
import android.util.Log;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.BinaryBitmap;
import com.google.zxing.DecodeHintType;
import com.google.zxing.LuminanceSource;
import com.google.zxing.MultiFormatReader;
import com.google.zxing.NotFoundException;
import com.google.zxing.PlanarYUVLuminanceSource;
import com.google.zxing.ReaderException;
import com.google.zxing.Result;
import com.google.zxing.common.HybridBinarizer;
import com.wix.RNCameraKit.camera.CameraViewManager;

import java.util.ArrayList;
import java.util.Collection;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;

import me.dm7.barcodescanner.core.DisplayUtils;

public class BarcodeScanner {

    public interface ResultHandler {
        void handleResult(Result rawResult);
    }

    private MultiFormatReader mMultiFormatReader;
    public static final List<BarcodeFormat> ALL_FORMATS = new ArrayList<>();
    private List<BarcodeFormat> mFormats;
    private ResultHandler mResultHandler;

    private Context context;
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

    public BarcodeScanner(Context context, Camera.PreviewCallback previewCallback) {
        this.context = context;
        this.previewCallback = previewCallback;
        initMultiFormatReader();
    }

    public void setFormats(List<BarcodeFormat> formats) {
        mFormats = formats;
        initMultiFormatReader();
    }

    public void setResultHandler(ResultHandler resultHandler) {
        mResultHandler = resultHandler;
    }

    public Collection<BarcodeFormat> getFormats() {
        if(mFormats == null) {
            return ALL_FORMATS;
        }
        return mFormats;
    }

    private void initMultiFormatReader() {
        Map<DecodeHintType,Object> hints = new EnumMap<>(DecodeHintType.class);
        hints.put(DecodeHintType.POSSIBLE_FORMATS, getFormats());
        mMultiFormatReader = new MultiFormatReader();
        mMultiFormatReader.setHints(hints);
    }

    public void onPreviewFrame(byte[] data, Camera camera) {
        if(mResultHandler == null) {
            return;
        }
        try {
            Camera.Parameters parameters = camera.getParameters();
            Camera.Size size = parameters.getPreviewSize();
            int width = size.width;
            int height = size.height;

            int tmp = width;
            width = height;
            height = tmp;
            data = getRotatedData(data, camera);

            LuminanceSource source = buildLuminanceSource(data, width, height);

            final Result finalRawResult = getFinalResult(source);

            if (finalRawResult != null) {
                Handler handler = new Handler(Looper.getMainLooper());
                handler.post(new Runnable() {
                    @Override
                    public void run() {
                        // Stopping the preview can take a little long.
                        // So we want to set result handler to null to discard subsequent calls to
                        // onPreviewFrame.
                        ResultHandler tmpResultHandler = mResultHandler;
                        mResultHandler = null;

                        camera.stopPreview();
                        if (tmpResultHandler != null) {
                            tmpResultHandler.handleResult(finalRawResult);
                        }
                    }
                });
            } else {
                camera.setOneShotPreviewCallback(previewCallback);
            }
        } catch(RuntimeException e) {
            // TODO: Terrible hack. It is possible that this method is invoked after camera is released.
            Log.w("CameraKit", e.toString());
        }
    }

    @Nullable
    private Result getFinalResult(LuminanceSource source) {
        Result rawResult = null;
        if (source != null) {
            BinaryBitmap bitmap = new BinaryBitmap(new HybridBinarizer(source));
            try {
                rawResult = mMultiFormatReader.decodeWithState(bitmap);
            } catch (ReaderException re) {
                // continue
            } catch (NullPointerException npe) {
                // This is terrible
            } catch (ArrayIndexOutOfBoundsException ignored) {

            } finally {
                mMultiFormatReader.reset();
            }

            if (rawResult == null && source.isRotateSupported()) {
                LuminanceSource rotatedSource = source.rotateCounterClockwise();
                bitmap = new BinaryBitmap(new HybridBinarizer(rotatedSource));
                try {
                    rawResult = mMultiFormatReader.decodeWithState(bitmap);
                } catch (NotFoundException e) {
                    // continue
                } finally {
                    mMultiFormatReader.reset();
                }
            }
          }
        return rawResult;
    }

    private LuminanceSource buildLuminanceSource(byte[] data, int width, int height) {
      Rect rect = CameraViewManager.getFramingRectInPreview(width, height);
      if (rect == null) {
          return null;
      }
      // Go ahead and assume it's YUV rather than die.
      LuminanceSource source = null;

      try {
          source = new RotateLuminanceSource(data, width, height, rect.left, rect.top,
                  rect.width(), rect.height(), false);
      } catch(Exception e) {
          e.printStackTrace();
      }

      return source;
  }

    private static byte[] getRotatedData(byte[] data, Camera camera) {
      Camera.Parameters parameters = camera.getParameters();
      Camera.Size size = parameters.getPreviewSize();
      int width = size.width;
      int height = size.height;

      byte[] rotatedData = new byte[data.length];
      for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++)
              rotatedData[x * height + height - y - 1] = data[x + y * width];
      }
      data = rotatedData;
      int tmp = width;
      width = height;
      height = tmp;

      return data;
  }
}
