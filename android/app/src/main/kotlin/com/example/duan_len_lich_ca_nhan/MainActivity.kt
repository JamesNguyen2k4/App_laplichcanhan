package com.example.duan_len_lich_ca_nhan

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.duan_len_lich_ca_nhan/vieneu_tts"
    private val neuCodecHandler = NeuCodecHandler()
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "decodeNeuCodec" -> {
                        val codesList = call.argument<List<Number>>("codes")
                        val modelPath = call.argument<String>("modelPath")
                        val outputPath = call.argument<String>("outputPath")

                        if (codesList == null || modelPath.isNullOrEmpty() || outputPath.isNullOrEmpty()) {
                            result.error("INVALID_ARGS", "Thiếu tham số codes, modelPath hoặc outputPath", null)
                            return@setMethodCallHandler
                        }

                        val codes = LongArray(codesList.size) { i -> codesList[i].toLong() }
                        executor.execute {
                            try {
                                val wavPath = neuCodecHandler.decodeToWav(codes, modelPath, outputPath)
                                mainHandler.post { result.success(wavPath) }
                            } catch (e: Exception) {
                                mainHandler.post {
                                    result.error("ONNX_ERROR", "Lỗi giải mã NeuCodec: ${e.message}", null)
                                }
                            }
                        }
                    }
                    "closeCodec" -> {
                        neuCodecHandler.close()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        neuCodecHandler.close()
        executor.shutdown()
        super.onDestroy()
    }
}
