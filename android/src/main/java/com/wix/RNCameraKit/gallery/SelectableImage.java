package com.wix.RNCameraKit.gallery;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.drawable.Drawable;
import android.provider.MediaStore;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.facebook.react.bridge.ReactContext;
import com.wix.RNCameraKit.Utils;

import java.util.concurrent.ThreadPoolExecutor;

import static android.view.ViewGroup.LayoutParams.MATCH_PARENT;
import static android.view.ViewGroup.LayoutParams.WRAP_CONTENT;

public class SelectableImage extends FrameLayout {
    private static final int MINI_THUMB_HEIGHT = 512;
    private static final int MINI_THUMB_WIDTH = 384;

    private static final int DEFAULT_SELECTED_IMAGE_GRAVITY = Gravity.TOP | Gravity.RIGHT;

    public static final int SELECTED_IMAGE_NORMAL_SIZE_DP = 22;
    public static final int SELECTED_IMAGE_LARGE_SIZE_DP = 36;

    private final ImageView imageView;
    private final ImageView selectedView;
    private final ReactContext reactContext;
    private final View selectedOverlay;

    private int id = -1;
    private Runnable currentLoader;
    private Drawable selectedDrawable;
    private Drawable unselectedDrawable;
    private LinearLayout unsupportedLayout;
    private ImageView unsupportedImage;
    private TextView unsupportedTextView;
    private int selectedOverlayColor = Color.parseColor("#80FFFFFF");
    private boolean selected;
    private int inSampleSize;

    public SelectableImage(ReactContext reactContext, Integer selectedImageGravity, Integer selectedImageSize) {
        super(reactContext.getApplicationContext());
        this.reactContext = reactContext;

        setPadding(1, 1, 1, 1);
        setBackgroundColor(0xedeff0);
        imageView = new ImageView(reactContext);
        addView(imageView, MATCH_PARENT, MATCH_PARENT);

        selectedOverlay = new View(reactContext);
        addView(selectedOverlay, MATCH_PARENT, MATCH_PARENT);

        selectedView = new ImageView(reactContext);
        addView(selectedView, createSelectedImageParams(selectedImageGravity, selectedImageSize));

        createUnsupportedView();
    }

    public void setUnsupportedUIParams(String overlayColor, Drawable unsupportedFinalImage, String unsupportedText, String unsupportedTextColor) {
        unsupportedLayout.setBackgroundColor(overlayColor != null ? Color.parseColor(overlayColor) : Color.TRANSPARENT);
        unsupportedImage.setImageDrawable(unsupportedFinalImage);
        unsupportedTextView.setTextColor(unsupportedTextColor != null ? Color.parseColor(unsupportedTextColor) : Color.WHITE);
        unsupportedTextView.setText(unsupportedText);

        unsupportedImage.setVisibility(unsupportedFinalImage != null ? VISIBLE : GONE);
        unsupportedTextView.setVisibility(unsupportedText != null && !unsupportedText.isEmpty() ? VISIBLE : GONE);
    }

    private void createUnsupportedView() {
        unsupportedLayout = new LinearLayout(getContext());
        unsupportedLayout.setBackgroundColor(Color.RED);
        addView(unsupportedLayout, MATCH_PARENT, MATCH_PARENT);
        unsupportedLayout.setOrientation(LinearLayout.VERTICAL);
        unsupportedLayout.setGravity(Gravity.CENTER);
        unsupportedLayout.setPadding(10, 10, 10, 10);

        unsupportedImage = new ImageView(getContext());
        unsupportedImage.setScaleType(ImageView.ScaleType.FIT_CENTER);
        unsupportedLayout.addView(unsupportedImage, new LinearLayout.LayoutParams(MATCH_PARENT, 0, 1));

        unsupportedTextView = new TextView(getContext());
        unsupportedTextView.setGravity(Gravity.CENTER);
        unsupportedLayout.addView(unsupportedTextView, WRAP_CONTENT, WRAP_CONTENT);
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, widthMeasureSpec);
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);
        this.inSampleSize = Utils.calculateInSampleSize(MINI_THUMB_WIDTH,MINI_THUMB_HEIGHT,w, h);
    }


    public void setScaleType(ImageView.ScaleType scaleType) {
        imageView.setScaleType(scaleType);
    }

    public void bind(ThreadPoolExecutor executor, boolean selected, boolean forceBind, final Integer id, boolean supported,final Integer orientation) {
        this.selected = selected;
        selectedView.setImageDrawable(selected ? selectedDrawable : unselectedDrawable);
        if (this.id != id || forceBind) {
            this.id = id;
            imageView.setImageBitmap(null);
            imageView.setBackgroundColor(Color.LTGRAY);
            if (currentLoader != null) {
                executor.remove(currentLoader);
            }

            currentLoader = new Runnable() {

                public Bitmap orient(final Bitmap bmp,final Integer orientation){
                    if (orientation != 0) {
                        Matrix matrix = new Matrix();
                        matrix.postRotate(orientation);
                        return Bitmap.createBitmap(bmp, 0, 0, bmp.getWidth(), bmp.getHeight(), matrix, true);
                    }
                    return bmp;
                }
                @Override
                public void run() {
                    BitmapFactory.Options options = new BitmapFactory.Options();
                    if (inSampleSize == 0) {
                        inSampleSize = Utils.calculateInSampleSize(MINI_THUMB_WIDTH,MINI_THUMB_HEIGHT, getWidth(), getHeight());
                    }
                    options.inSampleSize = inSampleSize;

                    final Bitmap bmp = orient(MediaStore.Images.Thumbnails.getThumbnail(
                            getContext().getContentResolver(),
                            id,
                            MediaStore.Images.Thumbnails.MINI_KIND,
                            options), orientation);

                    if (SelectableImage.this.id == id) {
                        reactContext.runOnUiQueueThread(new Runnable() {
                            @Override
                            public void run() {
                                imageView.setImageBitmap(bmp);
                            }
                        });
                    }
                }
            };
            executor.execute(currentLoader);
        }
        unsupportedLayout.setVisibility(supported ? GONE : VISIBLE);
        selectedView.setVisibility(supported ? VISIBLE : GONE);
    }

    @Override
    public boolean isSelected() {
        return selected;
    }

    @Override
    public void setSelected(boolean selected) {
        this.selected = selected;
        selectedView.setImageDrawable(selected ? selectedDrawable : unselectedDrawable);
        selectedOverlay.setBackgroundColor(selected ? this.selectedOverlayColor : Color.TRANSPARENT);
    }

    public void setDrawables(Drawable selectedDrawable, Drawable unselectedDrawable, Integer overlayColor) {
        this.selectedDrawable = selectedDrawable;
        this.unselectedDrawable = unselectedDrawable;
        this.selectedOverlayColor = overlayColor != null ? overlayColor : Color.parseColor("#80FFFFFF");
    }


    private LayoutParams createSelectedImageParams(Integer gravity, Integer sizeDp) {
        gravity = gravity != null ? gravity : DEFAULT_SELECTED_IMAGE_GRAVITY;
        sizeDp = sizeDp != null ? sizeDp : SELECTED_IMAGE_NORMAL_SIZE_DP;

        final int sizePx = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, sizeDp, getResources().getDisplayMetrics());

        final LayoutParams params = new FrameLayout.LayoutParams(sizePx, sizePx, gravity);
        params.setMargins(30, 30, 30, 30);
        return params;
    }
}
