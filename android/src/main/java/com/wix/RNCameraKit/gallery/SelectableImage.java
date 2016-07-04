package com.wix.RNCameraKit.gallery;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.TextView;

import static android.view.ViewGroup.LayoutParams.MATCH_PARENT;

/**
 * Created by yedidyak on 30/06/2016.
 */
public class SelectableImage extends FrameLayout {

    private final ImageView imageView;
    private final TextView selectedView;

    public SelectableImage(Context context) {
        super(context);
        imageView = new ImageView(context);
        addView(imageView, MATCH_PARENT, MATCH_PARENT);
        selectedView = new TextView(context);
        selectedView.setBackgroundColor(Color.BLUE);
        LayoutParams params = new LayoutParams(MATCH_PARENT, MATCH_PARENT);
        params.setMargins(30,30,30,30);
        addView(selectedView, params);
    }

    public void setSelected(int selectedPosition) {
        selectedView.setVisibility(selectedPosition > 0 ? VISIBLE : INVISIBLE);
        selectedView.setText("" + selectedPosition);
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, widthMeasureSpec);
    }

    public void setScaleType(ImageView.ScaleType scaleType) {
        imageView.setScaleType(scaleType);
    }

    public void setImageBitmap(Bitmap imageBitmap) {
        imageView.setImageBitmap(imageBitmap);
    }
}
