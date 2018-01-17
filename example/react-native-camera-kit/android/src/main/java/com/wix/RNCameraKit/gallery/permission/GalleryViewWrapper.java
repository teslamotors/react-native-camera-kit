package com.wix.RNCameraKit.gallery.permission;

import android.graphics.Color;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import com.wix.RNCameraKit.gallery.GalleryView;

public class GalleryViewWrapper extends FrameLayout {

    GalleryView view;

    public GalleryViewWrapper(GalleryView galleryView) {
        super(galleryView.getContext());
        view = galleryView;
        addView(view);
        setLayoutParams(new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        setBackgroundColor(Color.GREEN);
    }

    public void replaceGalleryView(GalleryView newGalleryView) {
        removeView(view);
        view = newGalleryView;
        addView(newGalleryView);
        setLayoutParams(new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
    }

    public GalleryView getGalleryView() {
        return view;
    }
}
