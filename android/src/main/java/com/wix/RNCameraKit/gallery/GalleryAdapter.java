package com.wix.RNCameraKit.gallery;

import android.database.Cursor;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.os.AsyncTask;
import android.provider.MediaStore;
import android.support.v4.util.Pair;
import android.support.v7.widget.RecyclerView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;

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
    private Drawable selectedDrawable;
    private Drawable unselectedDrawable;
    private boolean refreshing = false;

    public void setSelectedUris(ArrayList<String> selectedUris) {
        this.selectedUris = selectedUris;
    }

    public void setSelectedDrawable(Drawable selectedDrawable) {
        this.selectedDrawable = selectedDrawable;
        notifyView();
    }

    public void setUnselectedDrawable(Drawable unselectedDrawable) {
        this.unselectedDrawable = unselectedDrawable;
    }

    public Drawable getUnselectedDrawable() {
        return unselectedDrawable;
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

    @Override
    public int getItemViewType(int position) {
        return 0;
    }

    public void refreshData() {
        if(refreshing) return;
        refreshing = true;

        new Thread(new Runnable() {
           @Override
           public void run() {
               ids.clear();
               uris.clear();

               String selection = "";
               String[] args = null;
               if(albumName != null && !albumName.isEmpty() && !albumName.equals("All Photos")) {
                   selection = MediaStore.Images.Media.BUCKET_DISPLAY_NAME + "=?";
                   args = new String[]{albumName};
               }

               Cursor cursor = view.getContext().getContentResolver().query(
                       MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                       PROJECTION,
                       selection,
                       args,
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
               
               refreshing = false;

               notifyView();

           }
       }).start();
    }

    public void notifyView() {
        view.post(new Runnable() {
            @Override
            public void run() {
                if(!view.isComputingLayout()) {
                    notifyDataSetChanged();
                } else {
                    notifyView();
                }
            }
        });
    }

    private void setData(ArrayList<Integer> ids, ArrayList<String> uris) {
        this.ids = ids;
        this.uris = uris;
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
        holder.id = ids.get(position);
        holder.uri = uris.get(position);
        boolean selected = (selectedUris.indexOf(holder.uri) + 1) > 0;
        selectableImageView.setDrawables(selectedDrawable, unselectedDrawable);
        selectableImageView.bind(executor, selected, holder.id);
        selectableImageView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                view.onTapImage(holder.uri);
            }
        });
    }

    @Override
    public int getItemCount() {
        return ids.size();
    }
}
