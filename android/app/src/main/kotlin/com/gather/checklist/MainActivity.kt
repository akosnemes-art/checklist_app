package com.gather.checklist

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.graphics.Rect
import android.media.ExifInterface
import android.net.Uri
import android.os.Build
import android.view.RoundedCorner
import android.os.Bundle
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.paddle.ocr.EngineConfig
import com.paddle.ocr.PaddleOCR
import com.paddle.ocr.PaddleOCRConfig
import com.paddle.ocr.util.OpenCVUtils
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.io.ByteArrayInputStream
import java.io.File

class MainActivity : FlutterActivity(), SensorEventListener {
    companion object {
        private const val PICK_IMAGE_REQUEST = 4101
        private const val MAX_IMAGE_BYTES = 40 * 1024 * 1024
        private const val MAX_OCR_IMAGE_DIMENSION = 1600
        private const val MAX_OCR_DECODE_DIMENSION = MAX_OCR_IMAGE_DIMENSION * 2
        private const val TAG = "ChecklistOCR"
    }

    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null
    private var motionSink: EventChannel.EventSink? = null
    private var activityResumed = false
    private val ocrScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val recognitionLock = Mutex()
    private var paddleOCR: PaddleOCR? = null
    private var pendingOcrResult: MethodChannel.Result? = null
    private var scanningFrame = false
    private var websitePreviews: WebsitePreviewCapture? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.decorView.addOnLayoutChangeListener { view, _, _, _, _, _, _, _, _ ->
                val exclusionWidth = (40 * resources.displayMetrics.density).toInt()
                val exclusionHeight = (200 * resources.displayMetrics.density).toInt()
                val top = ((view.height - exclusionHeight) / 2).coerceAtLeast(0)
                view.systemGestureExclusionRects = listOf(
                    Rect(0, top, exclusionWidth, (top + exclusionHeight).coerceAtMost(view.height)),
                )
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "checklist/motion")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    motionSink = events
                    updateSensorRegistration()
                }

                override fun onCancel(arguments: Any?) {
                    motionSink = null
                    sensorManager.unregisterListener(this@MainActivity)
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "checklist/ocr")
            .setMethodCallHandler(::handleOcrCall)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "checklist/reminders")
            .setMethodCallHandler(::handleReminderCall)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "checklist/display")
            .setMethodCallHandler { call, result ->
                if (call.method != "roundedCornerRadius") {
                    result.notImplemented()
                } else if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
                    result.success(null)
                } else {
                    val view = window.decorView
                    view.post {
                        val insets = view.rootWindowInsets
                        val radii = listOf(
                            RoundedCorner.POSITION_TOP_LEFT,
                            RoundedCorner.POSITION_TOP_RIGHT,
                            RoundedCorner.POSITION_BOTTOM_LEFT,
                            RoundedCorner.POSITION_BOTTOM_RIGHT,
                        ).mapNotNull { insets?.getRoundedCorner(it)?.radius }
                        result.success(radii.maxOrNull()?.toDouble()?.div(resources.displayMetrics.density))
                    }
                }
            }

        val previews = WebsitePreviewCapture(this)
        websitePreviews = previews
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "checklist/website_previews")
            .setMethodCallHandler { call, result ->
                if (call.method == "capture") {
                    previews.capture(call.arguments as? String, result)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun handleReminderCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "sync") {
            result.notImplemented()
            return
        }
        try {
            val reminders = (call.arguments as? List<*>)?.mapNotNull { item ->
                val values = item as? Map<*, *> ?: return@mapNotNull null
                val id = values["id"] as? String ?: return@mapNotNull null
                val title = values["title"] as? String ?: return@mapNotNull null
                val timeMillis = (values["timeMillis"] as? Number)?.toLong()
                    ?: return@mapNotNull null
                ChecklistReminder(id = id, title = title, timeMillis = timeMillis)
            } ?: emptyList()
            ReminderScheduler.sync(applicationContext, reminders)
            requestNotificationPermissionIfNeeded(reminders.isNotEmpty())
            result.success(null)
        } catch (error: Exception) {
            result.error("reminder_sync_failed", error.message, error.toString())
        }
    }

    private fun requestNotificationPermissionIfNeeded(hasReminders: Boolean) {
        if (!hasReminders || Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) return
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            4203,
        )
    }

    private fun handleOcrCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickAndRecognise" -> {
                if (call.argument<String>("source") != "picture") {
                    result.error("invalid_source", "Choose a picture or take a photo.", null)
                } else if (beginOcr(result)) {
                    openPicturePicker()
                }
            }
            "recognisePhoto" -> {
                if (beginOcr(result)) recognisePhoto(call.argument<String>("path"))
            }
            "scanCameraFrame" -> scanCameraFrame(call, result)
            else -> result.notImplemented()
        }
    }

    private fun beginOcr(result: MethodChannel.Result): Boolean {
        if (pendingOcrResult != null) {
            result.error("ocr_busy", "Another image is already being processed.", null)
            return false
        }
        pendingOcrResult = result
        return true
    }

    private fun openPicturePicker() {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/*"
        }
        try {
            startActivityForResult(intent, PICK_IMAGE_REQUEST)
        } catch (error: Exception) {
            finishOcrError("picture_unavailable", "No picture picker is available.", error)
        }
    }

    private fun recognisePhoto(path: String?) {
        try {
            val imageFile = path?.let { File(it).canonicalFile }
            require(imageFile != null && imageFile.parentFile == cacheDir.canonicalFile && imageFile.isFile)
            recogniseImage(imageFile = imageFile)
        } catch (error: Exception) {
            finishOcrError("invalid_image", "The camera photo could not be opened.", error)
        }
    }

    @Deprecated("Uses the compatible activity-result path required by FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_IMAGE_REQUEST || pendingOcrResult == null) return
        if (resultCode != Activity.RESULT_OK) {
            finishOcrSuccess(null)
            return
        }

        val imageUri = data?.data
        if (imageUri == null) {
            finishOcrError("invalid_image", "The selected picture could not be opened.")
        } else {
            recogniseImage(imageUri = imageUri)
        }
    }

    private fun recogniseImage(imageUri: Uri? = null, imageFile: File? = null) {
        ocrScope.launch {
            try {
                val content = withContext(Dispatchers.IO) {
                    val bitmap = loadOcrBitmap(imageUri = imageUri, imageFile = imageFile)
                    try {
                        if (imageFile == null) {
                            recogniseText(bitmap, includeStyles = true)
                        } else {
                            readCameraLinks(bitmap, includeStyles = true)
                        }
                    } finally {
                        bitmap.recycle()
                    }
                }
                finishOcrSuccess(content)
            } catch (error: CancellationException) {
                throw error
            } catch (error: Throwable) {
                Log.e(TAG, "Offline OCR failed", error)
                val message = error.message?.takeIf { it.isNotBlank() }
                    ?: "Could not turn that image into text."
                finishOcrError("ocr_failed", message, error)
            }
        }
    }

    private fun scanCameraFrame(call: MethodCall, result: MethodChannel.Result) {
        if (scanningFrame || pendingOcrResult != null) {
            result.success(emptyMap<String, String>())
            return
        }
        scanningFrame = true
        ocrScope.launch {
            try {
                val links = withContext(Dispatchers.Default) {
                    val bitmap = CameraFrame(call).previewBitmap()
                    try {
                        readCameraLinks(bitmap)
                    } finally {
                        bitmap.recycle()
                    }
                }
                result.success(links)
            } catch (error: CancellationException) {
                result.error("activity_closed", "The image import was interrupted.", null)
                throw error
            } catch (error: Exception) {
                Log.w(TAG, "Camera preview scanning failed", error)
                result.error("scan_failed", error.message, null)
            } finally {
                scanningFrame = false
            }
        }
    }

    private suspend fun readCameraLinks(
        bitmap: Bitmap,
        includeStyles: Boolean = false,
    ): Map<String, Any> {
        val qr = CameraLinkScanner.readQr(bitmap)
        val result = try {
            recogniseText(bitmap, includeStyles)
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            if (qr == null) throw error
            Log.w(TAG, "Text recognition failed for a frame containing a QR code", error)
            mapOf("text" to "")
        }
        return if (qr == null) result else result + ("qr" to qr)
    }

    private suspend fun recogniseText(
        preparedBitmap: Bitmap,
        includeStyles: Boolean,
    ): Map<String, Any> = recognitionLock.withLock {
        if (paddleOCR == null && !OpenCVUtils.init(applicationContext)) {
            throw IllegalStateException("The offline image reader could not start.")
        }
        val engine = paddleOCR ?: PaddleOCR.create(
            context = applicationContext,
            config = PaddleOCRConfig(
                detLimitSideLen = MAX_OCR_IMAGE_DIMENSION,
                detLimitType = "max",
                detMaxSideLimit = MAX_OCR_IMAGE_DIMENSION,
                recScoreThresh = 0.3f,
            ),
            engineConfig = EngineConfig(numThreads = 4),
        ).also { paddleOCR = it }
        val lines = engine.recognize(preparedBitmap).results
        if (includeStyles) {
            try {
                return@withLock PhotoTextStyles.read(preparedBitmap, lines)
            } catch (error: Exception) {
                Log.w(TAG, "Could not read photo typography", error)
            }
        }
        mapOf("text" to lines.map { it.text.trim() }.filter { it.isNotEmpty() }.joinToString("\n"))
    }

    private fun loadOcrBitmap(imageUri: Uri?, imageFile: File?): Bitmap {
        val imageBytes = when {
            imageFile != null -> imageFile.readBytes()
            imageUri != null -> contentResolver.openInputStream(imageUri)?.use { it.readBytes() }
            else -> null
        } ?: throw IllegalStateException("The image is empty.")
        if (imageBytes.isEmpty() || imageBytes.size > MAX_IMAGE_BYTES) {
            throw IllegalArgumentException("Choose an image smaller than 40 MB.")
        }
        return decodeOcrBitmap(imageBytes)
    }

    private fun decodeOcrBitmap(imageBytes: ByteArray): Bitmap {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
            throw IllegalArgumentException("The selected image format could not be read.")
        }

        var sampleSize = 1
        val sourceMaxDimension = maxOf(bounds.outWidth, bounds.outHeight)
        while (sourceMaxDimension / sampleSize > MAX_OCR_DECODE_DIMENSION) {
            sampleSize *= 2
        }
        val decodeOptions = BitmapFactory.Options().apply {
            inSampleSize = sampleSize
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        var prepared = BitmapFactory.decodeByteArray(
            imageBytes,
            0,
            imageBytes.size,
            decodeOptions,
        ) ?: throw IllegalArgumentException("The selected image format could not be read.")

        val preparedMaxDimension = maxOf(prepared.width, prepared.height)
        if (preparedMaxDimension > MAX_OCR_IMAGE_DIMENSION) {
            val scale = MAX_OCR_IMAGE_DIMENSION.toFloat() / preparedMaxDimension
            val scaled = Bitmap.createScaledBitmap(
                prepared,
                (prepared.width * scale).toInt().coerceAtLeast(1),
                (prepared.height * scale).toInt().coerceAtLeast(1),
                true,
            )
            if (scaled !== prepared) prepared.recycle()
            prepared = scaled
        }

        val orientation = try {
            ByteArrayInputStream(imageBytes).use { stream ->
                ExifInterface(stream).getAttributeInt(
                    ExifInterface.TAG_ORIENTATION,
                    ExifInterface.ORIENTATION_NORMAL,
                )
            }
        } catch (_: Exception) {
            ExifInterface.ORIENTATION_NORMAL
        }
        val transform = exifTransform(orientation) ?: return prepared
        val oriented = Bitmap.createBitmap(
            prepared,
            0,
            0,
            prepared.width,
            prepared.height,
            transform,
            true,
        )
        if (oriented !== prepared) prepared.recycle()
        return oriented
    }

    private fun exifTransform(orientation: Int): Matrix? = when (orientation) {
        ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> Matrix().apply { setScale(-1f, 1f) }
        ExifInterface.ORIENTATION_ROTATE_180 -> Matrix().apply { setRotate(180f) }
        ExifInterface.ORIENTATION_FLIP_VERTICAL -> Matrix().apply { setScale(1f, -1f) }
        ExifInterface.ORIENTATION_TRANSPOSE -> Matrix().apply {
            setRotate(90f)
            postScale(-1f, 1f)
        }
        ExifInterface.ORIENTATION_ROTATE_90 -> Matrix().apply { setRotate(90f) }
        ExifInterface.ORIENTATION_TRANSVERSE -> Matrix().apply {
            setRotate(-90f)
            postScale(-1f, 1f)
        }
        ExifInterface.ORIENTATION_ROTATE_270 -> Matrix().apply { setRotate(-90f) }
        else -> null
    }

    private fun finishOcrSuccess(content: Any?) {
        pendingOcrResult?.success(content)
        pendingOcrResult = null
    }

    private fun finishOcrError(code: String, message: String, error: Throwable? = null) {
        pendingOcrResult?.error(code, message, error?.toString())
        pendingOcrResult = null
    }

    override fun onResume() {
        super.onResume()
        activityResumed = true
        if (::sensorManager.isInitialized) updateSensorRegistration()
    }

    override fun onPause() {
        activityResumed = false
        if (::sensorManager.isInitialized) sensorManager.unregisterListener(this)
        super.onPause()
    }

    private fun updateSensorRegistration() {
        val sensor = accelerometer ?: return
        if (motionSink != null && activityResumed) {
            sensorManager.unregisterListener(this)
            sensorManager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)
        }
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type != Sensor.TYPE_ACCELEROMETER) return
        motionSink?.success(
            listOf(event.values[0].toDouble(), event.values[1].toDouble()),
        )
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    override fun onDestroy() {
        websitePreviews?.close()
        pendingOcrResult?.error("activity_closed", "The image import was interrupted.", null)
        pendingOcrResult = null
        ocrScope.cancel()
        CoroutineScope(Dispatchers.IO).launch {
            recognitionLock.withLock {
                paddleOCR?.release()
                paddleOCR = null
            }
        }
        super.onDestroy()
    }
}
