package com.wix.RNCameraKit;

import android.content.Context;
import android.graphics.Color;
import android.graphics.Rect;
import android.support.v7.widget.GridLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.util.Log;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.Toast;

/**
 * Created by yedidyak on 30/06/2016.
 */
public class GalleryView extends RecyclerView {

    private String albumName;
    private GalleryAdapter adapter;
    private int itemSpacing;
    private int lineSpacing;

    public GalleryView(Context context) {
        super(context);
        setHasFixedSize(true);
        adapter = new GalleryAdapter(context);
        setAdapter(adapter);
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
        this.albumName = albumName;
        Toast.makeText(this.getContext(), albumName, Toast.LENGTH_SHORT).show();

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
        GridLayoutManager layoutManager = new GridLayoutManager(getContext(), columnCount);
        layoutManager.setOrientation(GridLayoutManager.VERTICAL);
        setLayoutManager(layoutManager);
    }
}
