package com.wix.RNCameraKit.gallery;

import android.app.Activity;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.provider.MediaStore;
import android.util.TypedValue;
import android.view.Gravity;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.facebook.react.bridge.ReactContext;

import java.util.concurrent.ThreadPoolExecutor;

import static android.view.ViewGroup.LayoutParams.MATCH_PARENT;
import static android.view.ViewGroup.LayoutParams.WRAP_CONTENT;

public class SelectableImage extends FrameLayout {
    private static final int MINI_THUMB_HEIGHT = 512;
    private static final int MINI_THUMB_WIDTH = 384;
    public static final int MAX_SAMPLE_SIZE = 8;

    private final ImageView imageView;
    private final ImageView selectedView;
    private int id = -1;
    private Runnable currentLoader;
    private Drawable selectedDrawable;
    private Drawable unselectedDrawable;
    private LinearLayout unsupportedLayout;
    private ImageView unsupportedImage;
    private TextView unsupportedTextView;
    private boolean selected;
    private int inSampleSize;

    public SelectableImage(Context context) {
        super(context);
        setPadding(1, 1, 1, 1);
        setBackgroundColor(0xedeff0);
        imageView = new ImageView(context);
        addView(imageView, MATCH_PARENT, MATCH_PARENT);
        selectedView = new ImageView(context);
        int dp22 = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 22, context.getResources().getDisplayMetrics());
        LayoutParams params = new FrameLayout.LayoutParams(dp22, dp22, Gravity.TOP | Gravity.RIGHT);
        params.setMargins(30, 30, 30, 30);
        addView(selectedView, params);
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
        this.inSampleSize = calculateInSampleSize(w, h);
    }

    public void setScaleType(ImageView.ScaleType scaleType) {
        imageView.setScaleType(scaleType);
    }

    public void bind(ThreadPoolExecutor executor, boolean selected, boolean forceBind, final Integer id, boolean supported) {
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
                @Override
                public void run() {

                    BitmapFactory.Options options = new BitmapFactory.Options();
                    if (inSampleSize == 0) {
                        inSampleSize = calculateInSampleSize(getWidth(), getHeight());
                    }
                    options.inSampleSize = inSampleSize;

                    final Bitmap bmp = MediaStore.Images.Thumbnails.getThumbnail(
                            getContext().getContentResolver(),
                            id,
                            MediaStore.Images.Thumbnails.MINI_KIND,
                            options);

                    if (SelectableImage.this.id == id) {
                        ((Activity) ((ReactContext) getContext()).getBaseContext()).runOnUiThread(new Runnable() {
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
    }

    public void setDrawables(Drawable selectedDrawable, Drawable unselectedDrawable) {
        this.selectedDrawable = selectedDrawable;
        this.unselectedDrawable = unselectedDrawable;
    }

    public static int calculateInSampleSize(int reqWidth, int reqHeight) {

        if (reqHeight == 0 || reqWidth == 0) {
            return 1;
        }

        int inSampleSize = 1;

        if (MINI_THUMB_HEIGHT > reqHeight || MINI_THUMB_WIDTH > reqWidth) {

            final int halfHeight = MINI_THUMB_HEIGHT / 2;
            final int halfWidth = MINI_THUMB_WIDTH / 2;

            while (inSampleSize <= MAX_SAMPLE_SIZE
                    && (halfHeight / inSampleSize) >= reqHeight
                    && (halfWidth / inSampleSize) >= reqWidth) {
                inSampleSize *= 2;
            }
        }

        return inSampleSize;
    }
}
