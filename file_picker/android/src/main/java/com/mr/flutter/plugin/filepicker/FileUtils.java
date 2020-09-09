package com.mr.flutter.plugin.filepicker;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.content.ContentUris;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.os.storage.StorageManager;
import android.provider.DocumentsContract;
import android.provider.MediaStore;
import android.text.TextUtils;
import android.util.Log;
import android.webkit.MimeTypeMap;

import androidx.annotation.Nullable;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Array;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Random;

public class FileUtils {

    private static final String TAG = "FilePickerUtils";
    private static final String PRIMARY_VOLUME_NAME = "primary";

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
                    return Environment.getExternalStorageDirectory() + (split.length > 1 ? ("/" + split[1]) : "");
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
                        try {
                            final Uri contentUri = ContentUris.withAppendedId(Uri.parse(contentUriPrefix), Long.valueOf(id));
                            final String path = getDataColumn(context, contentUri, null, null);
                            if (path != null) {
                                return path;
                            }
                        } catch (final Exception e) {
                            Log.e(TAG, "Something went wrong while retrieving document path: " + e.toString());
                            return null;
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

                final String selection = MediaStore.Images.Media._ID + "=?";
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

    public static String[] getMimeTypes(final ArrayList<String> allowedExtensions) {

        if (allowedExtensions == null || allowedExtensions.isEmpty()) {
            return null;
        }

        final ArrayList<String> mimes = new ArrayList<>();

        for (int i = 0; i < allowedExtensions.size(); i++) {
            final String mime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(allowedExtensions.get(i));
            if (mime == null) {
                Log.w(TAG, "Custom file type " + allowedExtensions.get(i) + " is unsupported and will be ignored.");
                continue;
            }

            mimes.add(mime);
        }
        Log.d(TAG, "Allowed file extensions mimes: " + mimes);
        return mimes.toArray(new String[0]);
    }

    private static String getDataColumn(final Context context, final Uri uri, final String selection,
                                        final String[] selectionArgs) {
        Cursor cursor = null;
        final String column = MediaStore.Images.Media.DATA;
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
            Cursor cursor = null;
            try {
                cursor = context.getContentResolver().query(uri, null, null, null, null);
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
            } catch (final Exception ex) {
                Log.e(TAG, "Failed to decode file name: " + ex.toString());
            } finally {
                if (cursor != null) {
                    cursor.close();
                }
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

    public static boolean clearCache(final Context context) {
        try {
            final File cacheDir = new File(context.getCacheDir() + "/file_picker/");
            final File[] files = cacheDir.listFiles();

            if (files != null) {
                for (final File file : files) {
                    file.delete();
                }
            }
        } catch (final Exception ex) {
            Log.e(TAG, "There was an error while clearing cached files: " + ex.toString());
            return false;
        }
        return true;
    }

    public static FileInfo openFileStream(final Context context, final Uri uri) {

        Log.i(TAG, "Caching from URI: " + uri.toString());
        FileOutputStream fos = null;
        final FileInfo.Builder fileInfo = new FileInfo.Builder();
        final String fileName = FileUtils.getFileName(uri, context);
        final String path = context.getCacheDir().getAbsolutePath() + "/file_picker/" + (fileName != null ? fileName : new Random().nextInt(100000));

        final File file = new File(path);
        file.getParentFile().mkdirs();

        try {
            fos = new FileOutputStream(path);
            try {
                final ByteArrayOutputStream out = new ByteArrayOutputStream();
                final InputStream in = context.getContentResolver().openInputStream(uri);

                final byte[] buffer = new byte[8192];
                int len = 0;

                while ((len = in.read(buffer)) >= 0) {
                    out.write(buffer, 0, len);
                }

                fileInfo.withData(out.toByteArray());
                out.writeTo(fos);
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

        Log.d(TAG, "File loaded and cached at:" + path);

        fileInfo
                .withPath(path)
                .withName(fileName)
                .withSize(Integer.parseInt(String.valueOf(file.length()/1024)))
                .withUri(uri);

        return fileInfo.build();
    }

    @Nullable
    public static FileInfo getFullPathFromTreeUri(@Nullable final Uri treeUri, Context con) {
        if (treeUri == null) {
            return null;
        }

        String volumePath = getVolumePath(getVolumeIdFromTreeUri(treeUri), con);
        FileInfo.Builder fileInfo = new FileInfo.Builder();

        fileInfo.withUri(treeUri);

        if (volumePath == null) {
            return fileInfo.withDirectory(File.separator).build();
        }

        if (volumePath.endsWith(File.separator))
            volumePath = volumePath.substring(0, volumePath.length() - 1);

        String documentPath = getDocumentPathFromTreeUri(treeUri);

        if (documentPath.endsWith(File.separator))
            documentPath = documentPath.substring(0, documentPath.length() - 1);

        if (documentPath.length() > 0) {
            if (documentPath.startsWith(File.separator)) {
                return fileInfo.withDirectory(volumePath + documentPath).build();
            }
            else {
                return fileInfo.withDirectory(volumePath + File.separator + documentPath).build();
            }
        } else {
            return fileInfo.withDirectory(volumePath).build();
        }
    }


    @SuppressLint("ObsoleteSdkInt")
    private static String getVolumePath(final String volumeId, Context context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return null;
        try {
            StorageManager mStorageManager =
                    (StorageManager) context.getSystemService(Context.STORAGE_SERVICE);
            Class<?> storageVolumeClazz = Class.forName("android.os.storage.StorageVolume");
            Method getVolumeList = mStorageManager.getClass().getMethod("getVolumeList");
            Method getUuid = storageVolumeClazz.getMethod("getUuid");
            Method getPath = storageVolumeClazz.getMethod("getPath");
            Method isPrimary = storageVolumeClazz.getMethod("isPrimary");
            Object result = getVolumeList.invoke(mStorageManager);

            final int length = Array.getLength(result);
            for (int i = 0; i < length; i++) {
                Object storageVolumeElement = Array.get(result, i);
                String uuid = (String) getUuid.invoke(storageVolumeElement);
                Boolean primary = (Boolean) isPrimary.invoke(storageVolumeElement);

                // primary volume?
                if (primary && PRIMARY_VOLUME_NAME.equals(volumeId))
                    return (String) getPath.invoke(storageVolumeElement);

                // other volumes?
                if (uuid != null && uuid.equals(volumeId))
                    return (String) getPath.invoke(storageVolumeElement);
            }
            // not found.
            return null;
        } catch (Exception ex) {
            return null;
        }
    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    private static String getVolumeIdFromTreeUri(final Uri treeUri) {
        final String docId = DocumentsContract.getTreeDocumentId(treeUri);
        final String[] split = docId.split(":");
        if (split.length > 0) return split[0];
        else return null;
    }


    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    private static String getDocumentPathFromTreeUri(final Uri treeUri) {
        final String docId = DocumentsContract.getTreeDocumentId(treeUri);
        final String[] split = docId.split(":");
        if ((split.length >= 2) && (split[1] != null)) return split[1];
        else return File.separator;
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