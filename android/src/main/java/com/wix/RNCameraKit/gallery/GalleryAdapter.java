package com.wix.RNCameraKit.gallery;

import android.database.Cursor;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.provider.MediaStore;
import android.support.v7.widget.RecyclerView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;

import com.wix.RNCameraKit.R;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.LinkedBlockingDeque;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

public class GalleryAdapter extends RecyclerView.Adapter<GalleryAdapter.AbsViewHolder> {

    private static int VIEW_TYPE_IMAGE = 0;
    private static int VIEW_TYPE_TAKE_PICTURE = 1;

    abstract class AbsViewHolder extends RecyclerView.ViewHolder {
        AbsViewHolder(View itemView) {
            super(itemView);
        }

        public abstract void bind(int position);
    }

    class ImageHolder extends AbsViewHolder implements View.OnClickListener {
        Image image;
        boolean isSupported = true;

        ImageHolder(SelectableImage itemView) {
            super(itemView);
        }

        public void bind(int position) {
            final Image image  = images.get(position);
            this.image = image;
            this.isSupported = isSupported(image);

            final boolean selected = isSelected();
            final boolean forceBind = hasImageChanged();

            final SelectableImage selectableImageView = (SelectableImage) this.itemView;
            selectableImageView.setUnsupportedUIParams(overlayColor, unsupportedFinalImage, unsupportedText, unsupportedTextColor);
            selectableImageView.setDrawables(selectedDrawable, unselectedDrawable);
            selectableImageView.bind(executor, selected, forceBind, image.id, this.isSupported);
            selectableImageView.setOnClickListener(this);
        }

        @Override
        public void onClick(View v) {
            if (this.isSupported) {
                view.onTapImage(ImageHolder.this.image.uri);
                v.setSelected(!v.isSelected());
            }
        }

        private boolean isSelected() {
            return (selectedUris.indexOf(image.uri) + 1) > 0;
        }

        private boolean isSupported(Image image) {
            if (supportedFileTypes.isEmpty()) {
                return true;
            } else {
                for (String supportedMime : supportedFileTypes) {
                    if (supportedMime == null) {
                        continue;
                    } else if (image.mimeType == null) {
                        return false;
                    } else if (image.mimeType.toLowerCase().equals(supportedMime.toLowerCase())) {
                        return true;
                    }
                }
                return false;
            }
        }

        private boolean hasImageChanged() {
            boolean hasImageChanged = (dirtyUris.indexOf(image.uri)) >= 0;
            if (hasImageChanged) {
                dirtyUris.remove(image.uri);
            }
            return hasImageChanged;
        }
    }

    class OpenCameraButtonHolder extends AbsViewHolder {

        OpenCameraButtonHolder() {
            super(new ImageView(GalleryAdapter.this.view.getContext()));
        }

        @Override
        public void bind(int position) {
            ImageView imageView = (ImageView) this.itemView;
            imageView.setImageResource(R.drawable.open_camera);
            imageView.setScaleType(ImageView.ScaleType.CENTER);
            imageView.setBackgroundColor(Color.parseColor("#f2f4f5"));
        }
    }

    private String overlayColor;
    private Drawable unsupportedFinalImage;
    private String unsupportedText;
    private String unsupportedTextColor;
    private List<String> dirtyUris = new ArrayList<>();
    private boolean embedCameraButton = true;

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

    void setDirtyUris(List<String> dirtyUris) {
        this.dirtyUris = dirtyUris;
    }

    public void setSelectedDrawable(Drawable selectedDrawable) {
        this.selectedDrawable = selectedDrawable;
    }

    public void setUnselectedDrawable(Drawable unselectedDrawable) {
        this.unselectedDrawable = unselectedDrawable;
    }

    public void setSupportedFileTypes(ArrayList<String> supportedFileTypes) {
        this.supportedFileTypes = supportedFileTypes;
    }

    public void setEmbedCameraButton(boolean embedCamera) {
        this.embedCameraButton = embedCamera;
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
    }

    @Override
    public int getItemViewType(int position) {
        if (shouldShowCameraButton() && position == 0) {
            return VIEW_TYPE_TAKE_PICTURE;
        }
        return VIEW_TYPE_IMAGE;
    }

    void refreshData() {
        if (refreshing) return;
        refreshing = true;

        new Thread(new Runnable() {
            @Override
            public void run() {
                int preItemsCount = getItemCount();

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

                if (shouldShowCameraButton()) {
                    images.add(new Image(null, -1, ""));
                }
                Collections.reverse(images);
                cursor.close();
                refreshing = false;
                notifyItemsLoaded(preItemsCount, getItemCount());
            }
        }).start();
    }

    private void notifyItemsLoaded(final int preCount, final int postCount) {
        view.post(new Runnable() {
            @Override
            public void run() {
                if (!view.isComputingLayout()) {
                    if (postCount > preCount) {
                        notifyItemRangeInserted(preCount, postCount - preCount);
                    } else if (postCount < preCount) {
                        notifyItemRangeRemoved(postCount, preCount - postCount);
                    }

                    if (preCount > 0) {
                        notifyItemRangeChanged(0, Math.min(preCount, postCount));
                    }
                } else {
                    view.postDelayed(new Runnable() {
                        @Override
                        public void run() {
                            notifyItemsLoaded(preCount, postCount);
                        }
                    }, 10);
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
    public AbsViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        if (viewType == VIEW_TYPE_IMAGE) {
            SelectableImage v = new SelectableImage(view.getContext());
            v.setScaleType(ImageView.ScaleType.CENTER_CROP);
            v.setBackgroundColor(Color.LTGRAY);
            return new ImageHolder(v);
        }

        if (viewType == VIEW_TYPE_TAKE_PICTURE) {
            return new OpenCameraButtonHolder();
        }

        return null;
    }

    @Override
    public void onBindViewHolder(final AbsViewHolder holder, final int position) {
        holder.bind(position);
    }

    @Override
    public long getItemId(int position) {
        return images.get(position).id;
    }

    @Override
    public int getItemCount() {
        return images.size();
    }

    private boolean shouldShowCameraButton() {
        return embedCameraButton;
    }
}
