package com.wix.RNCameraKit.gallery;

import android.content.Context;
import android.graphics.Rect;
import android.support.v7.widget.GridLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.util.Log;
import android.view.View;

public class GalleryView extends RecyclerView {

    private class GridLayoutViewManagerWrapper extends GridLayoutManager {

        GridLayoutViewManagerWrapper(Context context, int spanCount) {
            super(context, spanCount);
        }

        @Override
        public void onLayoutChildren(Recycler recycler, State state) {
            try {
                super.onLayoutChildren(recycler, state);
            } catch (IndexOutOfBoundsException e) {
                Log.e("WIX", "IOOBE in RecyclerView");
            }
        }
    }

    private int itemSpacing;
    private int lineSpacing;

    public GalleryView(Context context) {
        super(context);
        setHasFixedSize(true);
        getRecycledViewPool().setMaxRecycledViews(0, 20);
    }

    private void updateDecorator() {
        addItemDecoration(new ItemDecoration() {
            @Override
            public void getItemOffsets(Rect outRect, View view, RecyclerView parent, State state) {
                outRect.top = lineSpacing;
                outRect.left = itemSpacing;
                outRect.right = itemSpacing;
                outRect.bottom = lineSpacing;
            }
        });
    }

    public void setItemSpacing(int itemSpacing) {
        this.itemSpacing = itemSpacing;
        updateDecorator();
    }

    public void setLineSpacing(int lineSpacing) {
        this.lineSpacing = lineSpacing;
        updateDecorator();
    }

    public void setColumnCount(int columnCount) {
        if (getLayoutManager() == null || ((GridLayoutViewManagerWrapper) getLayoutManager()).getSpanCount() != columnCount) {
            GridLayoutManager layoutManager = new GridLayoutViewManagerWrapper(getContext(), columnCount);
            layoutManager.setOrientation(GridLayoutManager.VERTICAL);
            setLayoutManager(layoutManager);
        }
    }

}
