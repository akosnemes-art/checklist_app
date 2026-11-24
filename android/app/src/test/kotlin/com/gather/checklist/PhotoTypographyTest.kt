package com.gather.checklist

import org.junit.Assert.assertEquals
import org.junit.Test
import java.io.DataInputStream
import java.util.zip.GZIPInputStream

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
        assertStyles("mixed-styles", words)
    }

    @Test
    fun lightLetteringPreservesAccentsAndUnderline() {
        assertStyles(
            "light-hungarian",
            listOf("Árvíz" to 0, "tűrő" to PhotoTypography.BOLD, "tükör" to PhotoTypography.UNDERLINE),
        )
    }

    private fun assertStyles(fixture: String, words: List<Pair<String, Int>>) {
        val line = words.joinToString(" ") { it.first }
        val resource = checkNotNull(javaClass.getResourceAsStream("/photo-typography/$fixture.gray.gz"))
        val spans = DataInputStream(GZIPInputStream(resource).buffered()).use { input ->
            val photograph = input.readInk()
            // Each word has four styles in the fixture, with sans, serif and monospace samples.
            val templates = words.associate { (word, _) ->
                word to List(4) { List(3) { input.readInk() } }
            }
            PhotoTypography.detect(line, photograph) { word, flags -> templates.getValue(word)[flags] }
        }
        assertEquals(
            words.filter { it.second != 0 }.toMap(),
            spans.associate { span -> line.substring(span.start, span.end) to span.flags },
        )
    }

    private fun DataInputStream.readInk(): TextInk {
        val width = readUnsignedShort()
        val height = readUnsignedShort()
        val luma = IntArray(width * height) { readUnsignedByte() }
        return TextInk.threshold(width, height, luma)
    }
}
