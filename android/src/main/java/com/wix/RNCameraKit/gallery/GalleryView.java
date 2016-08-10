package com.wix.RNCameraKit.gallery;

import android.content.Context;
import android.graphics.Rect;
import android.graphics.drawable.Drawable;
import android.support.v7.widget.GridLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.util.Log;
import android.view.View;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.UIManagerModule;
import com.facebook.react.uimanager.events.Event;
import com.facebook.react.uimanager.events.RCTEventEmitter;

import java.util.ArrayList;

/**
 * Created by yedidyak on 30/06/2016.
 */
public class GalleryView extends RecyclerView {

    private class GridLayoutViewManagerWrapper extends GridLayoutManager {

        public GridLayoutViewManagerWrapper(Context context, int spanCount) {
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

    private GalleryAdapter adapter;
    private int itemSpacing;
    private int lineSpacing;

    public GalleryView(Context context) {
        super(context);
        setHasFixedSize(true);
        adapter = new GalleryAdapter(this);
        setAdapter(adapter);
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

    public void setAlbumName(String albumName) {
        adapter.setAlbum(albumName);
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
        GridLayoutManager layoutManager = new GridLayoutViewManagerWrapper(getContext(), columnCount);
        layoutManager.setOrientation(GridLayoutManager.VERTICAL);
        setLayoutManager(layoutManager);
    }

    public void onTapImage(String uri) {
        final ReactContext reactContext = ((ReactContext)getContext());
        reactContext.getNativeModule(UIManagerModule.class).getEventDispatcher().dispatchEvent(new TapImageEvent(uri));
    }

    public void setSelectedUris(ArrayList<String> selectedUris) {
        adapter.setSelectedUris(selectedUris);
        adapter.notifyView();
    }

    public void setSelectedDrawable(Drawable drawable) {
        adapter.setSelectedDrawable(drawable);
    }

    public void setUnselectedDrawable(Drawable drawable) {
        adapter.setUnselectedDrawable(drawable);
    }

    public void refresh() {
        adapter.refreshData();
    }

    private class TapImageEvent extends Event<TapImageEvent> {

        private WritableMap event;

        public TapImageEvent(String uri) {
            event = Arguments.createMap();
            event.putString("selected", uri);
            event.putString("id", "onTapImage");
            init(0, System.currentTimeMillis());
        }

        @Override
        public String getEventName() {
            return "onTapImage";
        }

        @Override
        public void dispatch(RCTEventEmitter rctEventEmitter) {
            rctEventEmitter.receiveEvent(getId(), "onTapImage", event);
        }
    }
}
