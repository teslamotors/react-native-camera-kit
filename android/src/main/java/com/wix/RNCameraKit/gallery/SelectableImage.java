package com.wix.RNCameraKit.gallery;

import android.app.Activity;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.provider.MediaStore;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.animation.Animation;
import android.view.animation.AnimationSet;
import android.view.animation.BounceInterpolator;
import android.view.animation.LinearInterpolator;
import android.view.animation.ScaleAnimation;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.facebook.react.bridge.ReactContext;

import java.util.concurrent.ThreadPoolExecutor;

import static android.view.ViewGroup.LayoutParams.MATCH_PARENT;
import static android.view.ViewGroup.LayoutParams.WRAP_CONTENT;

/**
 * Created by yedidyak on 30/06/2016.
 */
public class SelectableImage extends FrameLayout {

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

    public SelectableImage(Context context) {
        super(context);
        imageView = new ImageView(context);
        addView(imageView, MATCH_PARENT, MATCH_PARENT);
        selectedView = new ImageView(context);
        int dp22 = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 22, context.getResources().getDisplayMetrics());
        LayoutParams params = new FrameLayout.LayoutParams(dp22, dp22, Gravity.TOP | Gravity.RIGHT);
        params.setMargins(30,30,30,30);
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
        unsupportedLayout.setPadding(10,10,10,10);

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

    public void setScaleType(ImageView.ScaleType scaleType) {
        imageView.setScaleType(scaleType);
    }

    public void bind(ThreadPoolExecutor executor, boolean selected, final Integer id, boolean supported) {
        this.selected = selected;
        selectedView.setImageDrawable(selected ? selectedDrawable : unselectedDrawable);
        if (this.id != id) {
            this.id = id;
            imageView.setImageBitmap(null);
            imageView.setBackgroundColor(Color.LTGRAY);
            if (currentLoader != null) {
                executor.remove(currentLoader);
            }
            currentLoader = new Runnable() {
                @Override
                public void run() {
                    final Bitmap bmp = MediaStore.Images.Thumbnails.getThumbnail(
                            getContext().getContentResolver(),
                            id,
                            MediaStore.Images.Thumbnails.MINI_KIND,
                            null);

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
    }

    @Override
    public void setOnClickListener(final OnClickListener l) {
        super.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {

                animateBounce();

                l.onClick(v);
            }
        });
    }

    private void animateBounce() {
//        final float growTo = 0.9f;
//        final long duration = 100;
//
//        ScaleAnimation grow = new ScaleAnimation(1, growTo, 1, growTo,
//                Animation.RELATIVE_TO_SELF, 0.5f,
//                Animation.RELATIVE_TO_SELF, 0.5f);
//        grow.setDuration(duration / 2);
//        ScaleAnimation shrink = new ScaleAnimation(growTo, 1, growTo, 1,
//                Animation.RELATIVE_TO_SELF, 0.5f,
//                Animation.RELATIVE_TO_SELF, 0.5f);
//        shrink.setDuration(duration / 2);
//        shrink.setStartOffset(duration / 2);
//        AnimationSet growAndShrink = new AnimationSet(true);
//        growAndShrink.setInterpolator(new BounceInterpolator());
//        growAndShrink.addAnimation(shrink);
//        growAndShrink.addAnimation(grow);
//        this.startAnimation(growAndShrink);
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
}
