package com.wix.RNCameraKit;

import android.content.Context;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.AsyncTask;
import android.provider.MediaStore;
import android.support.v7.widget.RecyclerView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;

import java.util.ArrayList;

/**
 * Created by yedidyak on 30/06/2016.
 */
public class GalleryAdapter extends RecyclerView.Adapter<GalleryAdapter.StupidHolder> {


    public static final String[] PROJECTION = new String[]{
            MediaStore.Images.Media.DATA
    };

    private ArrayList<String> images = new ArrayList<>();

    public class StupidHolder extends RecyclerView.ViewHolder {
        public StupidHolder(View itemView) {
            super(itemView);
        }
    }

    private Context context;

    public GalleryAdapter(Context context) {
        this.context = context;
    }

    public void setAlbum(String albumName) {
        images.clear();

        String selection = null;
        if(albumName != null || !albumName.equals("All Photos")) {
            selection = MediaStore.Images.Media.BUCKET_DISPLAY_NAME + " = ?";
        }

        Cursor cursor = context.getContentResolver().query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                PROJECTION,
                selection,
                new String[]{albumName},
                null
        );

        if (cursor.moveToFirst()) {
            int dataIndex = cursor.getColumnIndex(MediaStore.Images.Media.DATA);
            do {
                images.add(cursor.getString(dataIndex));
            } while(cursor.moveToNext());
        }

        cursor.close();
    }

    @Override
    public StupidHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        ImageView v = new ImageView(context) {
            @Override
            protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
                super.onMeasure(widthMeasureSpec, widthMeasureSpec);
            }
        };
        v.setScaleType(ImageView.ScaleType.CENTER_CROP);
        return new StupidHolder(v);
    }

    @Override
    public void onBindViewHolder(final StupidHolder holder, final int position) {

        new AsyncTask<Void, Void, Bitmap>() {
            @Override
            protected Bitmap doInBackground(Void... params) {
                BitmapFactory.Options options = new BitmapFactory.Options();
                options.inSampleSize = 2;
                return BitmapFactory.decodeFile(images.get(position), options);
            }

            @Override
            protected void onPostExecute(Bitmap bitmap) {
                ((ImageView)holder.itemView).setImageBitmap(bitmap);
            }
        }.execute();
    }

    @Override
    public int getItemCount() {
        return images.size();
    }
}
