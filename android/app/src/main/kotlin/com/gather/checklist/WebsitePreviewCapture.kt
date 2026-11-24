package com.gather.checklist

import android.app.Activity
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.net.http.SslError
import android.os.Handler
import android.os.Looper
import android.view.View
import android.webkit.RenderProcessGoneDetail
import android.webkit.SslErrorHandler
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

internal class WebsitePreviewCapture(private val activity: Activity) {
    private val handler = Handler(Looper.getMainLooper())
    private var view: WebView? = null
    private var result: MethodChannel.Result? = null

    private fun isWebsite(uri: Uri): Boolean =
        (uri.scheme == "https" || uri.scheme == "http") &&
            !uri.host.isNullOrEmpty() && uri.userInfo == null

    fun capture(address: String?, reply: MethodChannel.Result) {
        if (result != null || address == null || !isWebsite(Uri.parse(address))) {
            reply.success(null)
            return
        }
        result = reply
        try {
            val container = activity.findViewById<FrameLayout>(android.R.id.content)
            val browser = WebView(activity)
            view = browser
            browser.importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
            browser.isFocusable = false
            browser.isClickable = false
            browser.settings.apply {
                allowFileAccess = false
                allowContentAccess = false
                javaScriptCanOpenWindowsAutomatically = false
                javaScriptEnabled = true
                offscreenPreRaster = true
                useWideViewPort = true
                loadWithOverviewMode = true
            }
            browser.webViewClient = object : WebViewClient() {
                private var generation = 0L

                override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest) =
                    !isWebsite(request.url)

                override fun onReceivedError(
                    view: WebView, request: WebResourceRequest, error: WebResourceError,
                ) {
                    if (request.isForMainFrame && this@WebsitePreviewCapture.view === view) close()
                }

                override fun onReceivedHttpError(
                    view: WebView, request: WebResourceRequest, response: WebResourceResponse,
                ) {
                    if (request.isForMainFrame && this@WebsitePreviewCapture.view === view) close()
                }

                override fun onReceivedSslError(view: WebView, handler: SslErrorHandler, error: SslError) {
                    handler.cancel()
                    if (this@WebsitePreviewCapture.view === view) close()
                }

                override fun onRenderProcessGone(view: WebView, detail: RenderProcessGoneDetail): Boolean {
                    if (this@WebsitePreviewCapture.view === view) close()
                    return true
                }

                override fun onPageFinished(view: WebView, url: String) {
                    if (this@WebsitePreviewCapture.view !== view || !isWebsite(Uri.parse(url))) return
                    val request = ++generation
                    // Give responsive pages time to paint after their load event.
                    handler.postDelayed({
                        if (this@WebsitePreviewCapture.view !== view || request != generation) {
                            return@postDelayed
                        }
                        view.postVisualStateCallback(request, object : WebView.VisualStateCallback() {
                            override fun onComplete(requestId: Long) {
                                if (requestId == generation) save(view)
                            }
                        })
                    }, 450)
                }
            }
            // Attach behind the opaque Flutter surface so WebView can finish drawing.
            container.addView(browser, 0, FrameLayout.LayoutParams(640, 480))
            handler.postDelayed({ close() }, 9000)
            browser.loadUrl(address)
        } catch (_: RuntimeException) {
            close()
        }
    }

    private fun save(browser: WebView) {
        if (view !== browser) return
        val bytes = try {
            val bitmap = Bitmap.createBitmap(640, 480, Bitmap.Config.ARGB_8888)
            try {
                browser.draw(Canvas(bitmap))
                ByteArrayOutputStream().use {
                    if (bitmap.compress(Bitmap.CompressFormat.WEBP, 80, it)) it.toByteArray()
                    else null
                }
            } finally {
                bitmap.recycle()
            }
        } catch (_: RuntimeException) {
            null
        }
        close(bytes)
    }

    fun close(bytes: ByteArray? = null) {
        handler.removeCallbacksAndMessages(null)
        val browser = view
        view = null
        if (browser != null) {
            (browser.parent as? FrameLayout)?.removeView(browser)
            browser.stopLoading()
            browser.destroy()
        }
        result?.success(bytes)
        result = null
    }
}
