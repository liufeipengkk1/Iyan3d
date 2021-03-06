package com.smackall.iyan3dPro.Helper;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.provider.MediaStore;

import com.smackall.iyan3dPro.EditorView;
import com.smackall.iyan3dPro.R;

import java.io.File;
import java.io.FileOutputStream;

/**
 * Created by Sabish.M on 17/3/16.
 * Copyright (c) 2015 Smackall Games Pvt Ltd. All rights reserved.
 */
public class ImageManager {
    private Context mContext;
    private int viewType;

    public ImageManager(Context context) {
        this.mContext = context;
    }

    public void getImageFromStorage(int viewType) {
        this.viewType = viewType;
        Intent i = new Intent(Intent.ACTION_PICK, android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
        try {
            ((Activity) mContext).startActivityForResult(i, Constants.IMAGE_IMPORT_RESPONSE);
        } catch (ActivityNotFoundException e) {
            UIHelper.informDialog(mContext, mContext.getString(R.string.gallery_not_found));
        }
    }

    public void startActivityForResult(Intent i, int requestCode, int resultCode) {
        ((EditorView) mContext).showOrHideLoading(Constants.SHOW);
        if (requestCode == Constants.IMAGE_IMPORT_RESPONSE && resultCode == Activity.RESULT_OK && null != i) {
            Uri selectedImage = i.getData();
            String[] filePathColumn = {MediaStore.Images.Media.DATA};
            Cursor cursor = mContext.getContentResolver().query(selectedImage,
                    filePathColumn, null, null, null);
            if (cursor != null) {
                cursor.moveToFirst();
            } else
                return;

            int columnIndex = cursor.getColumnIndex(filePathColumn[0]);
            String picturePath = cursor.getString(columnIndex);
            cursor.close();
            manageImageFile(picturePath);
        }
        ((EditorView) mContext).showOrHideLoading(Constants.HIDE);
    }

    public void manageImageFile(String path) {
        boolean exits = FileHelper.checkValidFilePath(path);
        if (exits) {
            ((EditorView) mContext).showOrHideLoading(Constants.SHOW);
            Bitmap bmp = null;
            try {
                bmp = BitmapFactory.decodeFile(path);
            } catch (OutOfMemoryError e) {
                UIHelper.informDialog(mContext, mContext.getString(R.string.outOfMemory));
            }
            if (bmp == null) return;
            savePng(bmp, PathManager.LocalThumbnailFolder + "/original" + FileHelper.getFileWithoutExt(path));
            bmp = null;
            makeThumbnail(path, "");
            scaleToSquare(path);
            if (viewType == Constants.IMPORT_IMAGES) {
                if (mContext != null && ((EditorView) mContext).imageSelection != null)
                    ((EditorView) mContext).imageSelection.notifyDataChanged();
            } else if (viewType == Constants.IMPORT_OBJ) {

            } else if (viewType == Constants.CHANGE_TEXTURE_MODE) {
                if (mContext != null && ((EditorView) mContext).textureSelection != null)
                    ((EditorView) mContext).textureSelection.notifyDataChanged();
            }
        }
    }

    public void makeThumbnail(String path, String fileName) {
        Bitmap bmp = null;
        try {
            bmp = BitmapFactory.decodeFile(path);
        } catch (OutOfMemoryError e) {
            UIHelper.informDialog(mContext, mContext.getString(R.string.outOfMemory));
        }
        if (bmp == null)
            return;
        Bitmap scaledBitmap = Bitmap.createScaledBitmap(bmp, 128, 128, false);
        savePng(scaledBitmap, PathManager.LocalThumbnailFolder + "/" + ((fileName.length() > 0) ? fileName : FileHelper.getFileWithoutExt(path)));
        scaledBitmap = null;
    }

    public void makeThumbnail(String path) {
        Bitmap bmp = null;
        try {
            bmp = BitmapFactory.decodeFile(path);
        } catch (OutOfMemoryError e) {
            UIHelper.informDialog(mContext, mContext.getString(R.string.outOfMemory));
        }
        if (bmp == null)
            return;
        Bitmap scaledBitmap = Bitmap.createScaledBitmap(bmp, 128, 128, false);
        savePng(scaledBitmap, PathManager.LocalThumbnailFolder + "/" + FileHelper.getFileWithoutExt(path));
        scaledBitmap = null;
    }

    private void scaleToSquare(String path) {
        Bitmap bmp = null;
        try {
            bmp = BitmapFactory.decodeFile(path);
        } catch (OutOfMemoryError e) {
            UIHelper.informDialog(mContext, mContext.getString(R.string.outOfMemory));
        }
        if (bmp == null) return;
        final int oriWidth = bmp.getWidth();
        final int oriHeight = bmp.getHeight();
        int maxSize = Math.max(oriHeight, oriWidth);
        int targetSize = 2;

        float bigSide = (oriWidth >= oriHeight) ? oriWidth : oriHeight;
        //Convert texture image size should be the 2 to the power values for convinent case.

        while (bigSide > targetSize && targetSize <= 1024)
            targetSize *= 2;

        Bitmap scaledBitmap = Bitmap.createScaledBitmap(bmp, targetSize, targetSize, false);
        savePng(scaledBitmap, PathManager.LocalImportedImageFolder + "/" + FileHelper.getFileWithoutExt(path));
        scaledBitmap = null;
    }

    public void savePng(Bitmap bitmap, String filePath) {
        try {
            File temp = new File(filePath);
            FileOutputStream os = new FileOutputStream(temp + ".png");
            bitmap.compress(Bitmap.CompressFormat.PNG, 50, os);
            os.flush();
            os.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
