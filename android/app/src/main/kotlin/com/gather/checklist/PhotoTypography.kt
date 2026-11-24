package com.gather.checklist

import kotlin.math.abs
import kotlin.math.ln
import kotlin.math.roundToInt

internal data class PhotoTextStyle(val start: Int, val end: Int, val flags: Int)

/** Pixel mask for a rectified OCR line or a rendered font sample. */
internal class TextInk(val width: Int, val height: Int, private val ink: BooleanArray) {
    operator fun get(x: Int, y: Int): Boolean = ink[y * width + x]

    fun without(rules: List<InkRule>): TextInk {
        if (rules.isEmpty()) return this
        val copy = ink.copyOf()
        for (rule in rules) {
            copy.fill(false, rule.row * width + rule.left, rule.row * width + rule.right)
        }
        return TextInk(width, height, copy)
    }

    fun bounds(left: Int = 0, right: Int = width): InkBounds? {
        var x0 = right
        var y0 = height
        var x1 = left
        var y1 = 0
        for (y in 0 until height) {
            for (x in left until right) {
                if (!this[x, y]) continue
                x0 = minOf(x0, x)
                y0 = minOf(y0, y)
                x1 = maxOf(x1, x + 1)
                y1 = maxOf(y1, y + 1)
            }
        }
        return if (x0 < x1 && y0 < y1) InkBounds(x0, y0, x1, y1) else null
    }

    companion object {
        fun threshold(width: Int, height: Int, luma: IntArray): TextInk {
            val histogram = IntArray(256)
            for (level in luma) histogram[level]++
            val total = luma.sum()
            var count = 0
            var sum = 0
            var limit = 0
            var bestSeparation = 0.0
            for (level in 0 until histogram.lastIndex) {
                count += histogram[level]
                sum += level * histogram[level]
                if (count == 0 || count == luma.size) continue
                val otherCount = luma.size - count
                val separation = sum.toDouble() / count - (total - sum).toDouble() / otherCount
                val score = separation * separation * count * otherCount
                if (score > bestSeparation) {
                    bestSeparation = score
                    limit = level
                }
            }
            val darkPixels = luma.count { it <= limit }
            val darkText = darkPixels <= luma.size / 2
            return TextInk(width, height, BooleanArray(luma.size) { index ->
                bestSeparation > 0 && (luma[index] <= limit) == darkText
            })
        }
    }
}

internal data class InkBounds(val left: Int, val top: Int, val right: Int, val bottom: Int) {
    val width: Int get() = right - left
    val height: Int get() = bottom - top
    val aspectRatio: Double get() = width.toDouble() / height
}

internal data class InkRule(val row: Int, val left: Int, val right: Int)

internal object PhotoTypography {
    const val BOLD = 1
    const val ITALIC = 2
    const val UNDERLINE = 4
    private const val MASK_WIDTH = 64
    private const val MASK_HEIGHT = 30
    private val word = Regex("\\S+")

    fun detect(
        text: String,
        line: TextInk,
        templates: (String, Int) -> List<TextInk>,
    ): List<PhotoTextStyle> {
        val words = word.findAll(text).toList()
        val bounds = line.bounds() ?: return emptyList()
        if (words.isEmpty() || bounds.height < 8) return emptyList()

        val rules = findRules(line, bounds)
        val letters = line.without(rules)
        val columns = wordColumns(letters, words.size) ?: return emptyList()
        return words.mapIndexedNotNull { index, match ->
            val glyphs = letters.bounds(columns[index], columns[index + 1])
                ?: return@mapIndexedNotNull null
            val underline = rules.any { rule ->
                rule.row >= glyphs.top + glyphs.height * 0.72 &&
                    minOf(rule.right, glyphs.right) - maxOf(rule.left, glyphs.left) >=
                    glyphs.width * 0.72
            }
            val lettering = if (match.value.length in 2..32 && glyphs.height >= 9) {
                matchFont(match.value, letters, glyphs, templates)
            } else {
                0
            }
            val styles = lettering or if (underline) UNDERLINE else 0
            if (styles == 0) null else PhotoTextStyle(match.range.first, match.range.last + 1, styles)
        }
    }

    private fun findRules(line: TextInk, bounds: InkBounds): List<InkRule> {
        val rules = mutableListOf<InkRule>()
        val minLength = maxOf(8, (bounds.height * 0.86).roundToInt())
        val firstRow = bounds.top + (bounds.height * 0.67).roundToInt()
        for (row in firstRow until bounds.bottom) {
            var start = bounds.left
            for (x in bounds.left..bounds.right) {
                if (x < bounds.right && line[x, row]) continue
                if (x - start >= minLength) rules.add(InkRule(row, start, x))
                start = x + 1
            }
        }
        return rules
    }

    private fun wordColumns(ink: TextInk, wordCount: Int): List<Int>? {
        val bounds = ink.bounds() ?: return null
        if (wordCount == 1) return listOf(bounds.left, bounds.right)
        val gaps = mutableListOf<IntRange>()
        var start = bounds.left
        for (x in bounds.left until bounds.right) {
            if ((bounds.top until bounds.bottom).none { y -> ink[x, y] }) continue
            if (start < x) gaps.add(start until x)
            start = x + 1
        }
        val minGap = maxOf(1, (bounds.height * 0.10).roundToInt())
        val breaks = gaps.sortedByDescending { it.last - it.first }
            .take(wordCount - 1)
            .filter { it.last - it.first + 1 >= minGap }
            .map { (it.first + it.last + 1) / 2 }
            .sorted()
        if (breaks.size != wordCount - 1) return null
        return listOf(bounds.left) + breaks + bounds.right
    }

    private fun matchFont(
        word: String,
        ink: TextInk,
        bounds: InkBounds,
        templates: (String, Int) -> List<TextInk>,
    ): Int {
        val scanned = normalize(ink, bounds)
        val scores = DoubleArray(4) { style ->
            templates(word, style).mapNotNull { template ->
                val region = template.bounds() ?: return@mapNotNull null
                val aspectPenalty = 0.3 * abs(ln(bounds.aspectRatio / region.aspectRatio))
                overlap(scanned, normalize(template, region)) - aspectPenalty
            }.maxOrNull() ?: 0.0
        }
        var result = 0
        for (flag in listOf(BOLD, ITALIC)) {
            val styled = scores.indices.filter { it and flag != 0 }.maxOf { scores[it] }
            val plain = scores.indices.filter { it and flag == 0 }.maxOf { scores[it] }
            if (styled >= 0.47 && styled >= plain + 0.035) result = result or flag
        }
        return result
    }

    private fun normalize(ink: TextInk, box: InkBounds): BooleanArray =
        BooleanArray(MASK_WIDTH * MASK_HEIGHT) { index ->
            val x = box.left + ((index % MASK_WIDTH + 0.5) * box.width / MASK_WIDTH).toInt()
            val y = box.top + ((index / MASK_WIDTH + 0.5) * box.height / MASK_HEIGHT).toInt()
            ink[x, y]
        }

    private fun overlap(scanned: BooleanArray, template: BooleanArray): Double {
        var best = 0.0
        for (dy in -1..1) {
            for (dx in -1..1) {
                var intersection = 0
                var union = 0
                for (y in 0 until MASK_HEIGHT) {
                    for (x in 0 until MASK_WIDTH) {
                        val a = scanned[y * MASK_WIDTH + x]
                        val tx = x + dx
                        val ty = y + dy
                        val b = tx in 0 until MASK_WIDTH && ty in 0 until MASK_HEIGHT &&
                            template[ty * MASK_WIDTH + tx]
                        if (a && b) intersection++
                        if (a || b) union++
                    }
                }
                if (union != 0) best = maxOf(best, intersection.toDouble() / union)
            }
        }
        return best
    }
}
