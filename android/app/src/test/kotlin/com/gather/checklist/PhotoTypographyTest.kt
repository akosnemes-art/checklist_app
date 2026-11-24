package com.gather.checklist

import org.junit.Assert.assertEquals
import org.junit.Test
import java.awt.Color
import java.awt.Font
import java.awt.RenderingHints
import java.awt.image.BufferedImage

class PhotoTypographyTest {
    @Test
    fun identifiesMixedWordFormatting() {
        val words = listOf(
            "plain" to 0,
            "bread" to PhotoTypography.BOLD,
            "fruit" to PhotoTypography.ITALIC,
            "milk" to PhotoTypography.UNDERLINE,
            "tea" to (PhotoTypography.BOLD or PhotoTypography.ITALIC or PhotoTypography.UNDERLINE),
        )
        assertStyles(words, darkText = true)
    }

    @Test
    fun lightLetteringPreservesAccentsAndUnderline() {
        assertStyles(
            listOf("Árvíz" to 0, "tűrő" to PhotoTypography.BOLD, "tükör" to PhotoTypography.UNDERLINE),
            darkText = false,
        )
    }

    private fun assertStyles(words: List<Pair<String, Int>>, darkText: Boolean) {
        val line = words.joinToString(" ") { it.first }
        val spans = PhotoTypography.detect(line, drawLine(words, darkText)) { word, flags ->
            listOf(Font.SANS_SERIF, Font.SERIF, Font.MONOSPACED).map { family ->
                drawLine(listOf(word to flags), darkText = true, family = family)
            }
        }
        assertEquals(
            words.filter { it.second != 0 }.toMap(),
            spans.associate { span -> line.substring(span.start, span.end) to span.flags },
        )
    }

    private fun drawLine(
        words: List<Pair<String, Int>>,
        darkText: Boolean,
        family: String = Font.SANS_SERIF,
    ): TextInk {
        val image = BufferedImage(1000, 75, BufferedImage.TYPE_INT_RGB)
        val canvas = image.createGraphics()
        val baseline = 55
        var cursor = 6
        canvas.color = if (darkText) Color.WHITE else Color.BLACK
        canvas.fillRect(0, 0, image.width, image.height)
        canvas.color = if (darkText) Color.BLACK else Color.WHITE
        canvas.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON)
        for ((word, flags) in words) {
            canvas.font = Font(family, flags and (Font.BOLD or Font.ITALIC), 48)
            canvas.drawString(word, cursor, baseline)
            val width = canvas.fontMetrics.stringWidth(word)
            if (flags and PhotoTypography.UNDERLINE != 0) {
                canvas.fillRect(cursor, baseline + 7, width, 2)
            }
            cursor += width + 16
        }
        canvas.dispose()
        val width = minOf(cursor, image.width)
        val luma = IntArray(width * image.height) { index ->
            image.getRGB(index % width, index / width) and 255
        }
        return TextInk.threshold(width, image.height, luma)
    }
}
