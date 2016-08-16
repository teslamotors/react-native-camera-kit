package com.wix.RNCameraKit.gallery;

import android.database.Cursor;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.provider.MediaStore;
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
public class GalleryAdapter extends RecyclerView.Adapter<GalleryAdapter.ImageHolder> {

    private String overlayColor;
    private Drawable unsupportedFinalImage;
    private String unsupportedText;
    private String unsupportedTextColor;

    private class Image {
        String uri;
        Integer id;
        String mimeType;

        public Image(String uri, Integer id, String mimeType) {
            this.uri = uri;
            this.id = id;
            this.mimeType = mimeType;
        }
    }

    public static final String[] PROJECTION = new String[]{
            MediaStore.Images.Media.DATA,
            MediaStore.Images.Media._ID,
            MediaStore.Images.Media.MIME_TYPE
    };

    private ArrayList<Image> images = new ArrayList<>();

    private ArrayList<String> selectedUris = new ArrayList<>();
    private ArrayList<String> supportedFileTypes = new ArrayList<>();
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
        notifyView();
    }

    public void setSupportedFileTypes(ArrayList<String> supportedFileTypes) {
        this.supportedFileTypes = supportedFileTypes;
        notifyView();
    }

    public class ImageHolder extends RecyclerView.ViewHolder {
        public ImageHolder(View itemView) {
            super(itemView);
        }
        Image image;
    }

    private GalleryView view;
    private ThreadPoolExecutor executor;

    public GalleryAdapter(GalleryView context) {
        this.view = context;
        setHasStableIds(true);
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
        if (refreshing) return;
        refreshing = true;

        new Thread(new Runnable() {
            @Override
            public void run() {
                images.clear();

                String selection = "";
                String[] args = null;
                if (albumName != null && !albumName.isEmpty() && !albumName.equals("All Photos")) {
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
                    int mimeIndex = cursor.getColumnIndex(MediaStore.Images.Media.MIME_TYPE);
                    do {
                        images.add(new Image(cursor.getString(dataIndex), cursor.getInt(idIndex), cursor.getString(mimeIndex)));
                    } while (cursor.moveToNext());
                }
                Collections.reverse(images);
                cursor.close();
                refreshing = false;
                notifyView(true);
            }
        }).start();
    }


    public void notifyView() {
        notifyView(false);
    }

    public void notifyView(final boolean refreshAll) {
        view.post(new Runnable() {
            @Override
            public void run() {
                if (!view.isComputingLayout()) {
                    view.swapAdapter(GalleryAdapter.this, false);
                    if(refreshAll) {
                        notifyItemRangeChanged(0, getItemCount());
                    }
                } else {
                    notifyView();
                }
            }
        });
    }

    public void setUnsupportedUIParams(String overlayColor, Drawable unsupportedFinalImage, String unsupportedText, String unsupportedTextColor) {
        this.overlayColor = overlayColor;
        this.unsupportedFinalImage = unsupportedFinalImage;
        this.unsupportedText = unsupportedText;
        this.unsupportedTextColor = unsupportedTextColor;
    }


    @Override
    public ImageHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        SelectableImage v = new SelectableImage(view.getContext());
        v.setScaleType(ImageView.ScaleType.CENTER_CROP);
        v.setBackgroundColor(Color.LTGRAY);
        return new ImageHolder(v);
    }



    @Override
    public void onBindViewHolder(final ImageHolder holder, final int position) {
        final SelectableImage selectableImageView = (SelectableImage)holder.itemView;
        holder.image = images.get(position);
        boolean selected = (selectedUris.indexOf(holder.image.uri) + 1) > 0;
        final boolean supported = isSupported(holder.image);
        selectableImageView.setUnsupportedUIParams(overlayColor, unsupportedFinalImage, unsupportedText, unsupportedTextColor);
        selectableImageView.setDrawables(selectedDrawable, unselectedDrawable);
        selectableImageView.bind(executor, selected, holder.image.id, supported);
        selectableImageView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if(supported) {
                    view.onTapImage(holder.image.uri);
                    v.setSelected(!v.isSelected());
                } else {

                }
            }
        });
    }

    @Override
    public long getItemId(int position) {
        return images.get(position).id;
    }

    private boolean isSupported(Image image) {
        if(supportedFileTypes.isEmpty()) {
            return true;
        } else {
            for(String supportedMime : supportedFileTypes) {
                if (image.mimeType.toLowerCase().equals(supportedMime.toLowerCase())) {
                    return true;
                }
            }
            return false;
        }
    }

    @Override
    public int getItemCount() {
        return images.size();
    }
}
