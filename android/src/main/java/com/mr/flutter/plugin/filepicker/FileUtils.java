package com.mr.flutter.plugin.filepicker;

import android.annotation.TargetApi;
import android.content.ContentUris;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.DocumentsContract;
import android.provider.MediaStore;
import android.text.TextUtils;
import android.util.Log;

import java.io.BufferedOutputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Random;

public class FileUtils {

    private static final String TAG = "FilePickerUtils";

    public static String getPath(final Uri uri, final Context context) {
        final boolean isKitKat = Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT;
        if (isKitKat) {
            return getForApi19(context, uri);
        } else if ("content".equalsIgnoreCase(uri.getScheme())) {
            if (isGooglePhotosUri(uri)) {
                return uri.getLastPathSegment();
            }
            return getDataColumn(context, uri, null, null);
        } else if ("file".equalsIgnoreCase(uri.getScheme())) {
            return uri.getPath();
        }
        return null;
    }

    @TargetApi(19)
    @SuppressWarnings("deprecation")
    private static String getForApi19(final Context context, final Uri uri) {
        Log.e(TAG, "Getting for API 19 or above" + uri);
        if (DocumentsContract.isDocumentUri(context, uri)) {
            Log.e(TAG, "Document URI");
            if (isExternalStorageDocument(uri)) {
                Log.e(TAG, "External Document URI");
                final String docId = DocumentsContract.getDocumentId(uri);
                final String[] split = docId.split(":");
                final String type = split[0];
                if ("primary".equalsIgnoreCase(type)) {
                    Log.e(TAG, "Primary External Document URI");
                    return Environment.getExternalStorageDirectory() + "/" + split[1];
                }
            } else if (isDownloadsDocument(uri)) {
                Log.e(TAG, "Downloads External Document URI");
                String id = DocumentsContract.getDocumentId(uri);

                if (!TextUtils.isEmpty(id)) {
                    if (id.startsWith("raw:")) {
                        return id.replaceFirst("raw:", "");
                    }
                    final String[] contentUriPrefixesToTry = new String[]{
                            "content://downloads/public_downloads",
                            "content://downloads/my_downloads",
                            "content://downloads/all_downloads"
                    };
                    if (id.contains(":")) {
                        id = id.split(":")[1];
                    }
                    for (final String contentUriPrefix : contentUriPrefixesToTry) {
                        final Uri contentUri = ContentUris.withAppendedId(Uri.parse(contentUriPrefix), Long.valueOf(id));
                        try {
                            final String path = getDataColumn(context, contentUri, null, null);
                            if (path != null) {
                                return path;
                            }
                        } catch (final Exception e) {
                            Log.e(TAG, "Something went wrong while retrieving document path: " + e.toString());
                        }
                    }

                }
            } else if (isMediaDocument(uri)) {
                Log.e(TAG, "Media Document URI");
                final String docId = DocumentsContract.getDocumentId(uri);
                final String[] split = docId.split(":");
                final String type = split[0];

                Uri contentUri = null;
                if ("image".equals(type)) {
                    Log.i(TAG, "Image Media Document URI");
                    contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
                } else if ("video".equals(type)) {
                    Log.i(TAG, "Video Media Document URI");
                    contentUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI;
                } else if ("audio".equals(type)) {
                    Log.i(TAG, "Audio Media Document URI");
                    contentUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;
                }

                final String selection = "_id=?";
                final String[] selectionArgs = new String[]{
                        split[1]
                };

                return getDataColumn(context, contentUri, selection, selectionArgs);
            }
        } else if ("content".equalsIgnoreCase(uri.getScheme())) {
            Log.e(TAG, "NO DOCUMENT URI - CONTENT: " + uri.getPath());
            if (isGooglePhotosUri(uri)) {
                return uri.getLastPathSegment();
            } else if (isDropBoxUri(uri)) {
                return null;
            }
            return getDataColumn(context, uri, null, null);
        } else if ("file".equalsIgnoreCase(uri.getScheme())) {
            Log.e(TAG, "No DOCUMENT URI - FILE: " + uri.getPath());
            return uri.getPath();
        }
        return null;
    }

    private static String getDataColumn(final Context context, final Uri uri, final String selection,
                                        final String[] selectionArgs) {
        Cursor cursor = null;
        final String column = "_data";
        final String[] projection = {
                column
        };
        try {
            cursor = context.getContentResolver().query(uri, projection, selection, selectionArgs,
                    null);
            if (cursor != null && cursor.moveToFirst()) {
                final int index = cursor.getColumnIndexOrThrow(column);
                return cursor.getString(index);
            }
        } catch (final Exception ex) {
        } finally {
            if (cursor != null) {
                cursor.close();
            }
        }
        return null;
    }

    public static String getFileName(Uri uri, final Context context) {
        String result = null;

        //if uri is content
        if (uri.getScheme() != null && uri.getScheme().equals("content")) {
            final Cursor cursor = context.getContentResolver().query(uri, null, null, null, null);
            try {
                if (cursor != null && cursor.moveToFirst()) {
                    //local filesystem
                    int index = cursor.getColumnIndex("_data");
                    if (index == -1)
                    //google drive
                    {
                        index = cursor.getColumnIndex("_display_name");
                    }
                    result = cursor.getString(index);
                    if (result != null) {
                        uri = Uri.parse(result);
                    } else {
                        return null;
                    }
                }
            } finally {
                cursor.close();
            }
        }

        if (uri.getPath() != null) {
            result = uri.getPath();
            final int cut = result.lastIndexOf('/');
            if (cut != -1) {
                result = result.substring(cut + 1);
            }
        }

        return result;
    }

    public static String getUriFromRemote(final Context context, final Uri uri) {

        Log.i(TAG, "Caching file from remote/external URI");
        FileOutputStream fos = null;
        final String fileName = FileUtils.getFileName(uri, context);
        final String externalFile = context.getCacheDir().getAbsolutePath() + "/" + (fileName != null ? fileName : new Random().nextInt(100000));

        try {
            fos = new FileOutputStream(externalFile);
            try {
                final BufferedOutputStream out = new BufferedOutputStream(fos);
                final InputStream in = context.getContentResolver().openInputStream(uri);

                final byte[] buffer = new byte[8192];
                int len = 0;

                while ((len = in.read(buffer)) >= 0) {
                    out.write(buffer, 0, len);
                }

                out.flush();
            } finally {
                fos.getFD().sync();
            }
        } catch (final Exception e) {
            try {
                fos.close();
            } catch (final IOException | NullPointerException ex) {
                Log.e(TAG, "Failed to close file streams: " + e.getMessage(), null);
                return null;
            }
            Log.e(TAG, "Failed to retrieve path: " + e.getMessage(), null);
            return null;
        }

        Log.i(TAG, "File loaded and cached at:" + externalFile);
        return externalFile;
    }

    private static boolean isDropBoxUri(final Uri uri) {
        return "com.dropbox.android.FileCache".equals(uri.getAuthority());
    }

    private static boolean isExternalStorageDocument(final Uri uri) {
        return "com.android.externalstorage.documents".equals(uri.getAuthority());
    }

    private static boolean isDownloadsDocument(final Uri uri) {
        return "com.android.providers.downloads.documents".equals(uri.getAuthority());
    }

    private static boolean isMediaDocument(final Uri uri) {
        return "com.android.providers.media.documents".equals(uri.getAuthority());
    }

    private static boolean isGooglePhotosUri(final Uri uri) {
        return "com.google.android.apps.photos.content".equals(uri.getAuthority());
    }

}