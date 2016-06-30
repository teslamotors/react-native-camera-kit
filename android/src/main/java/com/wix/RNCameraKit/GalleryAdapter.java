package com.wix.RNCameraKit;

import android.app.Activity;
import android.content.Context;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.provider.MediaStore;
import android.support.v7.widget.RecyclerView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;

import com.facebook.react.bridge.ReactContext;

import java.util.ArrayList;
import java.util.Collections;
import java.util.concurrent.LinkedBlockingDeque;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

/**
 * Created by yedidyak on 30/06/2016.
 */
public class GalleryAdapter extends RecyclerView.Adapter<GalleryAdapter.StupidHolder> {


    public static final String[] PROJECTION = new String[]{
            MediaStore.Images.Media.DATA,
            MediaStore.Images.Media._ID
    };

    private ArrayList<String> uris = new ArrayList<>();
    private ArrayList<Integer> ids = new ArrayList<>();
    private ArrayList<String> selectedUris = new ArrayList<>();
    private String albumName = "";

    public void setSelectedUris(ArrayList<String> selectedUris) {
        this.selectedUris = selectedUris;
    }

    public class StupidHolder extends RecyclerView.ViewHolder {
        public StupidHolder(View itemView) {
            super(itemView);
        }
        int id;
        String uri;
    }

    private GalleryView view;
    private ThreadPoolExecutor executor;

    public GalleryAdapter(GalleryView context) {
        this.view = context;
        int cores = Runtime.getRuntime().availableProcessors();
        executor = new ThreadPoolExecutor(cores, cores, 1, TimeUnit.SECONDS, new LinkedBlockingDeque<Runnable>());
        setAlbum(albumName);
    }

    public void setAlbum(String albumName) {
        this.albumName = albumName;
        refreshData();
    }

    public void refreshData() {
        ids.clear();

        String selection = "";
        if(albumName == null || albumName.isEmpty() || !albumName.equals("All Photos")) {
            selection = MediaStore.Images.Media.BUCKET_DISPLAY_NAME + " = ?";
        }

        Cursor cursor = view.getContext().getContentResolver().query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                PROJECTION,
                selection,
                new String[]{albumName},
                null
        );

        if (cursor.moveToFirst()) {
            int dataIndex = cursor.getColumnIndex(MediaStore.Images.Media.DATA);
            int idIndex = cursor.getColumnIndex(MediaStore.Images.Media._ID);
            do {
                uris.add(cursor.getString(dataIndex));
                ids.add(cursor.getInt(idIndex));
            } while(cursor.moveToNext());
        }

        Collections.reverse(uris);
        Collections.reverse(ids);

        cursor.close();
    }

    @Override
    public StupidHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        SelectableImage v = new SelectableImage(view.getContext());
        v.setScaleType(ImageView.ScaleType.CENTER_CROP);
        v.setBackgroundColor(Color.LTGRAY);
        return new StupidHolder(v);
    }

    @Override
    public void onBindViewHolder(final StupidHolder holder, final int position) {

        final SelectableImage selectableImageView = (SelectableImage)holder.itemView;
        selectableImageView.setImageBitmap(null);
        selectableImageView.setBackgroundColor(Color.LTGRAY);
        holder.id = ids.get(position);
        holder.uri = uris.get(position);

        selectableImageView.setSelected(selectedUris.indexOf(holder.uri) + 1);

        selectableImageView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                view.onTapImage(holder.uri);
            }
        });

        executor.execute(new Runnable() {
            @Override
            public void run() {
                final Bitmap bmp = MediaStore.Images.Thumbnails.getThumbnail(
                        view.getContext().getContentResolver(),
                        ids.get(holder.getAdapterPosition()),
                        MediaStore.Images.Thumbnails.MINI_KIND,
                        null);

                if (holder.id == ids.get(holder.getAdapterPosition())) {
                    ((Activity) ((ReactContext)view.getContext()).getBaseContext()).runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            selectableImageView.setImageBitmap(bmp);
                        }
                    });
                }
            }
        });
    }

    @Override
    public int getItemCount() {
        return ids.size();
    }
}
