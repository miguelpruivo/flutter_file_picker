package com.mr.flutter.plugin.filepicker;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.storage.StorageManager;
import android.provider.DocumentsContract;
import android.provider.OpenableColumns;
import android.util.Log;
import android.webkit.MimeTypeMap;

import androidx.annotation.Nullable;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Array;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;

public class FileUtils {

    private static final String TAG = "FilePickerUtils";
    private static final String PRIMARY_VOLUME_NAME = "primary";
    private static final Map uriToStreamMap = new HashMap<String, InputStream>();

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

    public static String getFileName(Uri uri, final Context context) {
        String result = null;

        try {

            if (uri.getScheme().equals("content")) {
                Cursor cursor = context.getContentResolver().query(uri, new String[]{OpenableColumns.DISPLAY_NAME}, null, null, null);
                try {
                    if (cursor != null && cursor.moveToFirst()) {
                        result = cursor.getString(cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME));
                    }
                } finally {
                    cursor.close();
                }
            }
            if (result == null) {
                result = uri.getPath();
                int cut = result.lastIndexOf('/');
                if (cut != -1) {
                    result = result.substring(cut + 1);
                }
            }
        } catch (Exception ex) {
            Log.e(TAG, "Failed to handle file name: " + ex.toString());
        }

        return result;
    }

    public static long getFileSize(Uri uri, final Context context) {
        long result = 0;

        try {

            if (uri.getScheme().equals("content")) {
                Cursor cursor = context.getContentResolver().query(uri, new String[]{OpenableColumns.SIZE}, null, null, null);
                try {
                    if (cursor != null && cursor.moveToFirst()) {
                        result = cursor.getLong(cursor.getColumnIndex(OpenableColumns.SIZE));
                    }
                } finally {
                    cursor.close();
                }
            }
        } catch (Exception ex) {
            Log.e(TAG, "Failed to handle file size: " + ex.toString());
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

    public static FileInfo openFileStream(final Context context, final Uri uri, boolean withData, boolean cachedFile) {
        if (cachedFile) {
            return openFileStreamWithoutCache(context, uri);
        } else {

            Log.i(TAG, "Caching from URI: " + uri.toString());
            FileOutputStream fos = null;
            final FileInfo.Builder fileInfo = new FileInfo.Builder();
            final String fileName = FileUtils.getFileName(uri, context);
            final String path = context.getCacheDir().getAbsolutePath() + "/file_picker/" + (fileName != null ? fileName : new Random().nextInt(100000));

            final File file = new File(path);

            if (file.exists() && withData) {
                int size = (int) file.length();
                byte[] bytes = new byte[size];

                try {
                    BufferedInputStream buf = new BufferedInputStream(new FileInputStream(file));
                    buf.read(bytes, 0, bytes.length);
                    buf.close();
                } catch (FileNotFoundException e) {
                    Log.e(TAG, "File not found: " + e.getMessage(), null);
                } catch (IOException e) {
                    Log.e(TAG, "Failed to close file streams: " + e.getMessage(), null);
                }
                fileInfo.withData(bytes);
            } else {

                file.getParentFile().mkdirs();
                try {
                    fos = new FileOutputStream(path);
                    try {
                        final BufferedOutputStream out = new BufferedOutputStream(fos);
                        final InputStream in = context.getContentResolver().openInputStream(uri);

                        final byte[] buffer = new byte[8192];
                        int len = 0;

                        while ((len = in.read(buffer)) >= 0) {
                            out.write(buffer, 0, len);
                        }

                        if (withData) {
                            try {
                                FileInputStream fis = null;
                                byte[] bytes = new byte[(int) file.length()];
                                fis = new FileInputStream(file);
                                fis.read(bytes);
                                fis.close();
                                fileInfo.withData(bytes);
                            } catch (Exception e) {
                                Log.e(TAG, "Failed to load bytes into memory with error " + e.toString() + ". Probably the file is too big to fit device memory. Bytes won't be added to the file this time.");
                            }
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
            }

            Log.d(TAG, "File loaded and cached at:" + path);

            fileInfo
                    .withPath(path)
                    .withName(fileName)
                    .withUri(uri)
                    .withSize(Long.parseLong(String.valueOf(file.length())));

            return fileInfo.build();
        }
    }

    public static FileInfo openFileStreamWithoutCache(final Context context, final Uri uri) {

        Log.i(TAG, "Caching from URI: " + uri.toString());
        final FileInfo.Builder fileInfo = new FileInfo.Builder();
        final String fileName = FileUtils.getFileName(uri, context);
        final String path = context.getCacheDir().getAbsolutePath() + "/file_picker/" + (fileName != null ? fileName : new Random().nextInt(100000));

        long fileSize = 0;
        try {
            fileSize = getFileSize(uri, context);
        } catch (Exception e) {
            e.printStackTrace();
        }
        Log.d(TAG, "File loaded and cached at:" + path);
        Log.d(TAG, "fileSize:" + fileSize);

        fileInfo
                .withPath(path)
                .withName(fileName)
                .withUri(uri)
                .withSize(fileSize);

        return fileInfo.build();
    }

    public static byte[] getBytesByUri(final Context context, final Uri uri, final int offset, final int size) {
        Log.d(TAG, "getBytesByUri-Uri:" + uri);
        byte[] bytes = null;

        try {
            bytes = new byte[size];
            InputStream inputStream;
            if (!uriToStreamMap.containsKey(uri)) {
                inputStream = openInputStreamByUri(context, uri);
            } else {
                inputStream = (FileInputStream) uriToStreamMap.get(uri);
            }
            int res = inputStream.read(bytes, offset, size);
            Log.d(TAG, "File InputStream length:" + res);
            if (res == -1) {
                closeInputStreamByUri(uri);
            }

        } catch (Exception e) {
            Log.d(TAG, "Failed to getBytesByUri:" + e.toString());
        }
        return bytes;
    }

    public static InputStream openInputStreamByUri(final Context context, final Uri uri) {
        InputStream inputStream = null;

        try {
            inputStream = context.getContentResolver().openInputStream(uri);
            uriToStreamMap.put(uri, inputStream);
        } catch (FileNotFoundException e) {
            Log.d(TAG, "Failed to openInputStreamByUri:" + e.toString());
        }

        return inputStream;
    }

    public static void closeInputStreamByUri(Uri uri) {
        if (uriToStreamMap.get(uri) != null) {
            InputStream inputStream = (InputStream) uriToStreamMap.get(uri);
            try {
                inputStream.close();
                uriToStreamMap.remove(uri);
            } catch (IOException e) {
                Log.d(TAG, "Failed to closeInputStreamByUri:" + e.toString());
            }
        }
    }

    @Nullable
    public static String getFullPathFromTreeUri(@Nullable final Uri treeUri, Context con) {
        if (treeUri == null) {
            return null;
        }

        String volumePath = getVolumePath(getVolumeIdFromTreeUri(treeUri), con);
        FileInfo.Builder fileInfo = new FileInfo.Builder();

        if (volumePath == null) {
            return File.separator;
        }

        if (volumePath.endsWith(File.separator))
            volumePath = volumePath.substring(0, volumePath.length() - 1);

        String documentPath = getDocumentPathFromTreeUri(treeUri);

        if (documentPath.endsWith(File.separator))
            documentPath = documentPath.substring(0, documentPath.length() - 1);

        if (documentPath.length() > 0) {
            if (documentPath.startsWith(File.separator)) {
                return volumePath + documentPath;
            } else {
                return volumePath + File.separator + documentPath;
            }
        } else {
            return volumePath;
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

}