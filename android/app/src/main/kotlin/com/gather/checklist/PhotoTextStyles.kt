package com.gather.checklist

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PointF
import android.graphics.Rect
import android.graphics.Typeface
import android.util.Log
import com.paddle.ocr.model.OCRBox
import com.paddle.ocr.model.OCRResult
import com.paddle.ocr.postprocess.QuadTextCrop
import org.opencv.android.Utils
import org.opencv.core.Mat

internal object PhotoTextStyles {
    private val fonts = Array(4) { style ->
        listOf("sans-serif", "serif", "monospace").map { Typeface.create(it, style) }
    }

    fun read(bitmap: Bitmap, lines: List<OCRResult>): Map<String, Any> {
        val text = StringBuilder()
        val styles = mutableListOf<List<Int>>()
        val source = Mat()
        try {
            Utils.bitmapToMat(bitmap, source)
            for (line in lines) {
                val value = line.text.trim()
                if (value.isEmpty()) continue
                if (text.isNotEmpty()) text.append('\n')
                val offset = text.length
                text.append(value)
                for (run in detectLine(value, source, line.box)) {
                    styles.add(listOf(offset + run.start, offset + run.end, run.flags))
                }
            }
        } finally {
            source.release()
        }
        return mapOf("text" to text.toString(), "styles" to styles)
    }

    private fun detectLine(text: String, source: Mat, box: OCRBox): List<PhotoTextStyle> {
        if (box.points.size != 4) return emptyList()
        return try {
            val (topLeft, topRight, bottomRight, bottomLeft) = box.points
            // Include the space immediately below the letters so underlines
            // just outside the recognition crop can still be identified.
            val expanded = OCRBox(
                listOf(
                    topLeft, topRight,
                    extendBelow(topRight, bottomRight),
                    extendBelow(topLeft, bottomLeft),
                ),
            )
            val crop = QuadTextCrop.crop(source, expanded)
            try {
                if (crop.empty() || crop.cols() < 8 || crop.rows() < 8) return emptyList()
                val line = Bitmap.createBitmap(crop.cols(), crop.rows(), Bitmap.Config.ARGB_8888)
                try {
                    Utils.matToBitmap(crop, line)
                    PhotoTypography.detect(text, mask(line), ::fontSamples)
                } finally {
                    line.recycle()
                }
            } finally {
                crop.release()
            }
        } catch (error: Exception) {
            Log.w("ChecklistOCR", "Could not read lettering styles for an OCR line", error)
            emptyList()
        }
    }

    private fun extendBelow(top: PointF, bottom: PointF): PointF = PointF(
        bottom.x + (bottom.x - top.x) * 0.20f,
        bottom.y + (bottom.y - top.y) * 0.20f,
    )

    private fun fontSamples(word: String, style: Int): List<TextInk> = fonts[style].map { typeface ->
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.BLACK
            textSize = 48f
            this.typeface = typeface
        }
        val bounds = Rect()
        paint.getTextBounds(word, 0, word.length, bounds)
        val bitmap = Bitmap.createBitmap(bounds.width() + 8, bounds.height() + 8, Bitmap.Config.ARGB_8888)
        try {
            bitmap.eraseColor(Color.WHITE)
            Canvas(bitmap).drawText(word, 4f - bounds.left, 4f - bounds.top, paint)
            mask(bitmap)
        } finally {
            bitmap.recycle()
        }
    }

    private fun mask(bitmap: Bitmap): TextInk {
        val width = bitmap.width
        val height = bitmap.height
        val luma = IntArray(width * height)
        bitmap.getPixels(luma, 0, width, 0, 0, width, height)
        for (index in luma.indices) {
            val pixel = luma[index]
            luma[index] = (
                Color.red(pixel) * 299 + Color.green(pixel) * 587 + Color.blue(pixel) * 114
            ) / 1000
        }
        return TextInk.threshold(width, height, luma)
    }
}
