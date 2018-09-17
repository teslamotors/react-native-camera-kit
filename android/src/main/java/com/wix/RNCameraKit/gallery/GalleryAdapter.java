package com.wix.RNCameraKit.gallery;

import android.database.Cursor;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.provider.MediaStore;
import android.support.v7.widget.RecyclerView;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;

import com.facebook.react.bridge.ReactContext;
import com.facebook.react.uimanager.UIManagerModule;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.LinkedBlockingDeque;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

public class GalleryAdapter extends RecyclerView.Adapter<GalleryAdapter.AbsViewHolder> {

    public static final int SELECTED_IMAGE_SIZE_NORMAL = SelectableImage.SELECTED_IMAGE_NORMAL_SIZE_DP;
    public static final int SELECTED_IMAGE_SIZE_LARGE = SelectableImage.SELECTED_IMAGE_LARGE_SIZE_DP;

    private static final int[] selectedPositionTypeToGravity = new int[] {
            Gravity.TOP | Gravity.RIGHT,
            Gravity.TOP | Gravity.LEFT,
            Gravity.BOTTOM | Gravity.RIGHT,
            Gravity.BOTTOM | Gravity.LEFT,
            Gravity.CENTER
    };

    private static final int DEFAULT_CUSTOM_BUTTON_BACKGROUND_COLOR = Color.parseColor("#f2f4f5");

    private static int VIEW_TYPE_IMAGE = 0;
    private static int VIEW_TYPE_CUSTOM_BUTTON = 1;

    private static final String[] PROJECTION = new String[]{
            MediaStore.Images.Media.DATA,
            MediaStore.Images.Media._ID,
            MediaStore.Images.Media.MIME_TYPE,
            MediaStore.Images.Media.WIDTH,
            MediaStore.Images.Media.HEIGHT,
            MediaStore.Images.Media.ORIENTATION
    };

    private class Image {
        String uri;
        Integer id;
        String mimeType;
        Integer width;
        Integer height;
        Integer orientation;

        public Image(String uri, Integer id, String mimeType, Integer width, Integer height,Integer orientation) {
            this.uri = uri;
            this.id = id;
            this.mimeType = mimeType;
            this.width = width;
            this.height = height;
            this.orientation = orientation;
        }
    }

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
            selectableImageView.setDrawables(selectedDrawable, unselectedDrawable, selectionOverlayColor);
            selectableImageView.bind(executor, selected, forceBind, image.id, isSupported,image.orientation);
            selectableImageView.setOnClickListener(this);
        }

        @Override
        public void onClick(View v) {
            if (!isSupported) {
                return;
            }

            final boolean isSelected = v.isSelected();
            if (!enableSelection && !isSelected) {
                return;
            }

            onTapImage(image.uri, image.width, image.height);
            // optimistically update the selection state for responsiveness -
            // ultimately the selection state will be reset based on the
            // imagesSelected prop which should be updated based on the
            // onTapImage handler
            v.setSelected(!isSelected);
            if (isSelected) {
                selectedUris.remove(image.uri);
            } else {
                selectedUris.add(image.uri);
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

    class CustomButtonViewHolder extends AbsViewHolder implements View.OnClickListener {

        CustomButtonViewHolder() {
            super(new ImageView(GalleryAdapter.this.reactContext.getApplicationContext()));

            final ImageView imageView = (ImageView) this.itemView;
            imageView.setScaleType(ImageView.ScaleType.CENTER);
            imageView.setOnClickListener(this);
        }

        @Override
        public void bind(int position) {
            final ImageView imageView = (ImageView) this.itemView;
            imageView.setImageDrawable(GalleryAdapter.this.customButtonImage);
            imageView.setBackgroundColor(GalleryAdapter.this.customButtonBackgroundColor);
        }

        @Override
        public void onClick(View v) {
            onTapCustomButton();
        }
    }

    private String overlayColor;
    private Integer selectionOverlayColor;
    private Drawable unsupportedFinalImage;
    private String unsupportedText;
    private String unsupportedTextColor;
    private List<String> dirtyUris = new ArrayList<>();
    private ArrayList<String> selectedUris = new ArrayList<>();
    private ArrayList<String> supportedFileTypes = new ArrayList<>();
    private String albumName = "";
    private Drawable selectedDrawable;
    private Drawable customButtonImage;
    private Integer selectedDrawableGravity;
    private Integer selectedDrawableSize;
    private Drawable unselectedDrawable;
    private int customButtonBackgroundColor = DEFAULT_CUSTOM_BUTTON_BACKGROUND_COLOR;
    private boolean enableSelection = true;

    private final GalleryView galleryView;
    private final ReactContext reactContext;
    private final ThreadPoolExecutor executor;

    private boolean isDirty = true;
    private ArrayList<Image> images = new ArrayList<>();
    private HashMap<String, Integer> imagePositions = new HashMap<>();

    public GalleryAdapter(ReactContext reactContext, GalleryView galleryView) {
        this.reactContext = reactContext;
        this.galleryView = galleryView;
        setHasStableIds(true);
        int cores = Runtime.getRuntime().availableProcessors();
        executor = new ThreadPoolExecutor(cores, cores, 1, TimeUnit.SECONDS, new LinkedBlockingDeque<Runnable>());
        setAlbum(albumName);
    }

    public void setAlbum(String albumName) {
        this.albumName = albumName;

        isDirty = true;
    }

    public void setSelectedUris(ArrayList<String> selectedUris) {
        ArrayList<String> oldSelectedUris = this.selectedUris;
        this.selectedUris = selectedUris;
        updateSelectedItems(oldSelectedUris, selectedUris);
    }

    void setDirtyUris(List<String> dirtyUris) {
        this.dirtyUris = dirtyUris;

        isDirty = true;
    }

    public void setSelectedDrawable(Drawable selectedDrawable) {
        this.selectedDrawable = selectedDrawable;
    }

    public void setUnselectedDrawable(Drawable unselectedDrawable) {
        this.unselectedDrawable = unselectedDrawable;
    }

    public void setSelectionDrawablePosition(int positionType) {
        this.selectedDrawableGravity = selectedPositionTypeToGravity[positionType];
    }

    public void setSelectedDrawableSize(int selectedDrawableSize) {
        this.selectedDrawableSize = selectedDrawableSize;
    }

    public void setSelectionOverlayColor(Integer overlayColor) {
        this.selectionOverlayColor = overlayColor;
    }

    public void setSupportedFileTypes(ArrayList<String> supportedFileTypes) {
        this.supportedFileTypes = supportedFileTypes;

        isDirty = true;
    }

    public void setUnsupportedUIParams(String overlayColor, Drawable unsupportedFinalImage, String unsupportedText, String unsupportedTextColor) {
        this.overlayColor = overlayColor;
        this.unsupportedFinalImage = unsupportedFinalImage;
        this.unsupportedText = unsupportedText;
        this.unsupportedTextColor = unsupportedTextColor;
    }

    public void setCustomButtonImage(Drawable customButtonImage) {
        this.customButtonImage = customButtonImage;
    }

    public void setCustomButtonBackgroundColor(int color) {
        this.customButtonBackgroundColor = color;
    }

    public void setShouldEnabledSelection(Boolean enable) {
        this.enableSelection = enable;
    }

    @Override
    public int getItemViewType(int position) {
        if (shouldShowCustomButton() && position == 0) {
            return VIEW_TYPE_CUSTOM_BUTTON;
        }
        return VIEW_TYPE_IMAGE;
    }

    void refreshData() {
        refreshData(false);
    }

    void refreshData(boolean force) {
        if (!isDirty && !force) {
            return;
        }
        isDirty = false;

        int preItemsCount = getItemCount();
        images.clear();
        imagePositions.clear();

        String selection = "";
        String[] args = null;
        if (albumName != null && !albumName.isEmpty() && !albumName.equals("All Photos")) {
            selection = MediaStore.Images.Media.BUCKET_DISPLAY_NAME + "=?";
            args = new String[]{albumName};
        }

        Cursor cursor = reactContext.getApplicationContext().getContentResolver().query(
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
            int widthIndex = cursor.getColumnIndex(MediaStore.Images.Media.WIDTH);
            int heightIndex = cursor.getColumnIndex(MediaStore.Images.Media.HEIGHT);
            int orientationIndex = cursor.getColumnIndex(MediaStore.Images.Media.ORIENTATION);
            do {
                images.add(new Image(cursor.getString(dataIndex), cursor.getInt(idIndex), cursor.getString(mimeIndex),
                        cursor.getInt(widthIndex), cursor.getInt(heightIndex), cursor.getInt(orientationIndex)));
            } while (cursor.moveToNext());
        }

        if (shouldShowCustomButton()) {
            images.add(new Image(null, -1, "", 0, 0,0));
        }
        Collections.reverse(images);
        int index = 0;
        for (Image img : images) {
            if (img.uri != null) {
                imagePositions.put(img.uri, index);
            }
            index++;
        }
        cursor.close();
        notifyItemsLoaded(preItemsCount, getItemCount());
    }

    private void notifyItemsLoaded(final int preCount, final int postCount) {
        reactContext.runOnUiQueueThread(new Runnable() {
            @Override
            public void run() {
                if (!galleryView.isComputingLayout()) {
                    if (preCount == 0) {
                        notifyItemRangeInserted(0, postCount);
                    } else {
                        galleryView.swapAdapter(GalleryAdapter.this, true);
                    }
                    // http://stackoverflow.com/a/42549611/453052
                    galleryView.scrollBy(0, 0);
                } else {
                    new Timer().schedule(new TimerTask() {
                        @Override
                        public void run() {
                            notifyItemsLoaded(preCount, postCount);
                        }
                    }, 10);
                }
            }
        });
    }

    private void updateSelectedItems(final ArrayList<String> oldSelections, final ArrayList<String> newSelections) {
        // get intersection of new and old for unchanged selections
        HashSet<String> unchangedImageUris = new HashSet<>(oldSelections);
        unchangedImageUris.retainAll(newSelections);

        // get union of new and old and remove the intersection for the changedImageUris
        HashSet<String> changedImageUris = new HashSet<>(oldSelections);
        changedImageUris.addAll(newSelections);
        changedImageUris.removeAll(unchangedImageUris);

        if (!changedImageUris.isEmpty()) {
            ArrayList<Integer> changedImagePositions = new ArrayList<>(changedImageUris.size());
            for (String changedUri: changedImageUris) {
                Integer imagePosition = imagePositions.get(changedUri);
                if (imagePosition != null) {
                    changedImagePositions.add(imagePosition);
                }
            }
            notifyItemsChanged(changedImagePositions);
        }
    }

    private void notifyItemsChanged(final List<Integer> changedPositions) {
        reactContext.runOnUiQueueThread(new Runnable() {
            @Override
            public void run() {
                if (!galleryView.isComputingLayout()) {
                    for (int pos: changedPositions) {
                        notifyItemChanged(pos);
                    }
                    // http://stackoverflow.com/a/42549611/453052
                    galleryView.scrollBy(0, 0);
                } else {
                    new Timer().schedule(new TimerTask() {
                        @Override
                        public void run() {
                            notifyItemsChanged(changedPositions);
                        }
                    }, 10);
                }
            }
        });
    }

    @Override
    public AbsViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        if (viewType == VIEW_TYPE_IMAGE) {
            SelectableImage v = new SelectableImage(reactContext, selectedDrawableGravity, selectedDrawableSize);
            v.setScaleType(ImageView.ScaleType.CENTER_CROP);
            v.setBackgroundColor(Color.LTGRAY);
            return new ImageHolder(v);
        }

        if (viewType == VIEW_TYPE_CUSTOM_BUTTON) {
            return new CustomButtonViewHolder();
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

    private boolean shouldShowCustomButton() {
        return customButtonImage != null;
    }

    public void onTapImage(String uri, Integer width, Integer height) {
        reactContext.getNativeModule(UIManagerModule.class).getEventDispatcher().dispatchEvent(new TapImageEvent(getRootViewId(), uri, width, height));
    }

    public void onTapCustomButton() {
        reactContext.getNativeModule(UIManagerModule.class).getEventDispatcher().dispatchEvent(new TapCustomButtonEvent(getRootViewId()));
    }

    private int getRootViewId() {
        return galleryView.getId();
    }
}
