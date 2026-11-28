package com.gather.checklist

import java.io.InputStream
import java.io.OutputStream

internal fun copyPhotoInput(input: InputStream, output: OutputStream, limit: Int) {
    val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
    var size = 0
    while (true) {
        val count = input.read(buffer)
        if (count == -1) return
        require(count <= limit - size) { "Choose an image smaller than 40 MB." }
        output.write(buffer, 0, count)
        size += count
    }
}
