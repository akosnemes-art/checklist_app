package com.gather.checklist

import android.graphics.Bitmap
import android.graphics.Matrix
import com.google.zxing.BinaryBitmap
import com.google.zxing.DecodeHintType
import com.google.zxing.RGBLuminanceSource
import com.google.zxing.ReaderException
import com.google.zxing.common.HybridBinarizer
import com.google.zxing.qrcode.QRCodeReader
import io.flutter.plugin.common.MethodCall
import kotlin.math.roundToInt

internal class CameraFrame(call: MethodCall) {
    private val luma = requireNotNull(call.argument<ByteArray>("luma"))
    private val width = requireNotNull(call.argument<Int>("width"))
    private val height = requireNotNull(call.argument<Int>("height"))
    private val rowStride = requireNotNull(call.argument<Int>("rowStride"))
    private val pixelStride = requireNotNull(call.argument<Int>("pixelStride"))
    private val rotation = requireNotNull(call.argument<Int>("rotation"))
    private val aspectRatio = requireNotNull(call.argument<Double>("aspectRatio"))

    init {
        require(width > 0 && height > 0 && rowStride > 0 && pixelStride > 0)
        require(rotation in setOf(0, 90, 180, 270) && aspectRatio.isFinite() && aspectRatio > 0)
        val lastPixel = (height - 1L) * rowStride + (width - 1L) * pixelStride
        require(lastPixel < luma.size && width.toLong() * height <= luma.size)
    }

    fun previewBitmap(): Bitmap {
        // Match the preview's centred BoxFit.cover crop in the sensor coordinates.
        val sensorRatio = if (rotation == 90 || rotation == 270) 1 / aspectRatio else aspectRatio
        val cropWidth = (height * sensorRatio).roundToInt().coerceIn(1, width)
        val cropHeight = (width / sensorRatio).roundToInt().coerceIn(1, height)
        val left = (width - cropWidth) / 2
        val top = (height - cropHeight) / 2
        val pixels = IntArray(cropWidth * cropHeight)
        var destination = 0
        for (row in top until top + cropHeight) {
            var source = row * rowStride + left * pixelStride
            for (column in 0 until cropWidth) {
                val grey = luma[source].toInt() and 0xff
                pixels[destination++] = (0xff shl 24) or (grey * 0x010101)
                source += pixelStride
            }
        }
        val bitmap = Bitmap.createBitmap(pixels, cropWidth, cropHeight, Bitmap.Config.ARGB_8888)
        if (rotation == 0) return bitmap
        return try {
            Bitmap.createBitmap(
                bitmap, 0, 0, cropWidth, cropHeight,
                Matrix().apply { setRotate(rotation.toFloat()) },
                false,
            )
        } finally {
            bitmap.recycle()
        }
    }
}

internal object CameraLinkScanner {
    private val qrHints = mapOf(DecodeHintType.TRY_HARDER to true)

    fun readQr(bitmap: Bitmap): String? {
        val width = bitmap.width
        val height = bitmap.height
        val pixels = IntArray(width * height)
        bitmap.getPixels(pixels, 0, width, 0, 0, width, height)
        return readQr(pixels, width, height)
    }

    internal fun readQr(pixels: IntArray, width: Int, height: Int): String? {
        val source = RGBLuminanceSource(width, height, pixels)
        return try {
            QRCodeReader().decode(BinaryBitmap(HybridBinarizer(source)), qrHints).text
        } catch (_: ReaderException) {
            null
        }
    }
}
