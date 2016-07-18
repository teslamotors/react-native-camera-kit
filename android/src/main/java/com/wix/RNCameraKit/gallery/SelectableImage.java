package com.wix.RNCameraKit.gallery;

import android.app.Activity;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.provider.MediaStore;
import android.util.Log;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.TextView;

import com.facebook.react.bridge.ReactContext;

import java.util.concurrent.ThreadPoolExecutor;

import static android.view.ViewGroup.LayoutParams.MATCH_PARENT;

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

    public SelectableImage(Context context) {
        super(context);
        imageView = new ImageView(context);
        addView(imageView, MATCH_PARENT, MATCH_PARENT);
        selectedView = new ImageView(context);
        int dp22 = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 22, context.getResources().getDisplayMetrics());
        LayoutParams params = new FrameLayout.LayoutParams(dp22, dp22, Gravity.TOP | Gravity.RIGHT);
        params.setMargins(30,30,30,30);
        addView(selectedView, params);
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, widthMeasureSpec);
    }

    public void setScaleType(ImageView.ScaleType scaleType) {
        imageView.setScaleType(scaleType);
    }

    public void bind(ThreadPoolExecutor executor, boolean selected, final Integer id) {
//        selectedView.setVisibility(selected ? VISIBLE : INVISIBLE);
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
    }

    public void setDrawables(Drawable selectedDrawable, Drawable unselectedDrawable) {
        this.selectedDrawable = selectedDrawable;
        this.unselectedDrawable = unselectedDrawable;
    }
}
