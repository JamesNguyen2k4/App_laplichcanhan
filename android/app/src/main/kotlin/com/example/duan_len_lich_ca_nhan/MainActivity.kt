package com.example.duan_len_lich_ca_nhan

import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
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
                    "copyAssetToFile" -> {
                        val assetPath = call.argument<String>("assetPath")
                        val targetPath = call.argument<String>("targetPath")

                        if (assetPath.isNullOrEmpty() || targetPath.isNullOrEmpty()) {
                            result.error("INVALID_ARGS", "Thiếu assetPath hoặc targetPath", null)
                            return@setMethodCallHandler
                        }

                        executor.execute {
                            try {
                                val targetFile = File(targetPath)
                                if (targetFile.exists() && targetFile.length() > 0L) {
                                    mainHandler.post { result.success(true) }
                                    return@execute
                                }
                                targetFile.parentFile?.mkdirs()

                                val loader = FlutterInjector.instance().flutterLoader()
                                val lookupKey = loader.getLookupKeyForAsset(assetPath)
                                val tempFile = File("$targetPath.tmp")

                                applicationContext.assets.open(lookupKey).use { input ->
                                    FileOutputStream(tempFile).use { output ->
                                        val buffer = ByteArray(65536) // Stream 64KB - không tốn RAM
                                        var bytesRead: Int
                                        while (input.read(buffer).also { bytesRead = it } != -1) {
                                            output.write(buffer, 0, bytesRead)
                                        }
                                        output.flush()
                                    }
                                }

                                if (tempFile.exists() && tempFile.length() > 0L) {
                                    tempFile.renameTo(targetFile)
                                    mainHandler.post { result.success(true) }
                                } else {
                                    tempFile.delete()
                                    mainHandler.post { result.success(false) }
                                }
                            } catch (e: Throwable) {
                                mainHandler.post { result.success(false) }
                            }
                        }
                    }
                    "generateSpeechTokens" -> {
                        val modelPath = call.argument<String>("modelPath")
                        val prompt = call.argument<String>("prompt")
                        val maxTokens = call.argument<Int>("maxTokens") ?: 1024
                        val temperature = (call.argument<Double>("temperature") ?: 1.0).toFloat()
                        val topK = call.argument<Int>("topK") ?: 50

                        if (modelPath.isNullOrEmpty() || prompt.isNullOrEmpty()) {
                            result.error("INVALID_ARGS", "Thiếu modelPath hoặc prompt", null)
                            return@setMethodCallHandler
                        }

                        executor.execute {
                            try {
                                val tokens = LlamaBridge.generateSpeechTokens(
                                    modelPath,
                                    prompt,
                                    maxTokens,
                                    temperature,
                                    topK
                                )
                                mainHandler.post { result.success(tokens) }
                            } catch (e: Throwable) {
                                mainHandler.post {
                                    result.error("LLAMA_ERROR", "Lỗi sinh tokens GGUF: ${e.message}", null)
                                }
                            }
                        }
                    }
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
                            } catch (e: Throwable) {
                                mainHandler.post {
                                    result.error("ONNX_ERROR", "Lỗi giải mã NeuCodec: ${e.message}", null)
                                }
                            }
                        }
                    }
                    "closeCodec" -> {
                        neuCodecHandler.close()
                        try {
                            LlamaBridge.freeModel()
                        } catch (_: Throwable) {}
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        neuCodecHandler.close()
        try {
            LlamaBridge.freeModel()
        } catch (_: Throwable) {}
        executor.shutdown()
        super.onDestroy()
    }
}
