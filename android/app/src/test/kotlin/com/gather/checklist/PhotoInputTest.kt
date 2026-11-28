package com.gather.checklist

import java.io.ByteArrayOutputStream
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class PhotoInputTest {
    @Test fun acceptsExactLimitAndRejectsTheFirstOversizeChunk() {
        val original = ByteArray(8192) { it.toByte() }
        val output = ByteArrayOutputStream()
        copyPhotoInput(original.inputStream(), output, original.size)
        assertArrayEquals(original, output.toByteArray())
        output.reset()
        assertThrows(IllegalArgumentException::class.java) {
            copyPhotoInput((original + 0.toByte()).inputStream(), output, original.size)
        }
        assertEquals(original.size, output.size())
    }
}
