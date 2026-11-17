package com.example.duan_len_lich_ca_nhan

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.LongBuffer
import kotlin.math.max
import kotlin.math.min

/**
 * Native ONNX Runtime handler cho NeuCodec Decoder (24kHz) trên Android.
 * Chuyển đổi mảng speech token IDs (sinh ra từ 0.3B GGUF) thành file âm thanh .wav.
 */
class NeuCodecHandler {
    private var ortEnv: OrtEnvironment? = null
    private var ortSession: OrtSession? = null
    private var loadedModelPath: String? = null

    fun ensureLoaded(modelPath: String) {
        if (ortSession != null && loadedModelPath == modelPath) return
        close()
        val env = OrtEnvironment.getEnvironment()
        val opts = OrtSession.SessionOptions().apply {
            setIntraOpNumThreads(2)
            setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT)
        }
        ortEnv = env
        ortSession = env.createSession(modelPath, opts)
        loadedModelPath = modelPath
    }

    /**
     * Giải mã speech codes [1, 1, N] -> FloatArray PCM 24kHz -> ghi ra file WAV 16-bit.
     */
    fun decodeToWav(codes: LongArray, modelPath: String, outputWavPath: String): String {
        ensureLoaded(modelPath)
        val env = ortEnv ?: throw IllegalStateException("OrtEnvironment chưa được khởi tạo")
        val session = ortSession ?: throw IllegalStateException("OrtSession chưa được khởi tạo")

        val inputName = session.inputNames.firstOrNull() ?: "codes"
        val shape = longArrayOf(1L, 1L, codes.size.toLong())
        val tensor = OnnxTensor.createTensor(env, LongBuffer.wrap(codes), shape)

        tensor.use { inputTensor ->
            val result = session.run(mapOf(inputName to inputTensor))
            result.use { ortResult ->
                val rawValue = ortResult[0].value
                val pcm = extractPcmFloatArray(rawValue)
                writeWav16Bit(pcm, 24000, outputWavPath)
            }
        }
        return outputWavPath
    }

    private fun extractPcmFloatArray(value: Any?): FloatArray {
        return when (value) {
            is Array<*> -> {
                // Shape thường là [1, 1, T] hoặc [1, T]
                val first = value.firstOrNull()
                if (first is Array<*>) {
                    val inner = first.firstOrNull()
                    if (inner is FloatArray) inner else FloatArray(0)
                } else if (first is FloatArray) {
                    first
                } else {
                    FloatArray(0)
                }
            }
            is FloatArray -> value
            else -> FloatArray(0)
        }
    }

    private fun writeWav16Bit(pcm: FloatArray, sampleRate: Int, outputPath: String) {
        val numSamples = pcm.size
        val dataSize = numSamples * 2
        val totalSize = 36 + dataSize

        val header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN).apply {
            put("RIFF".toByteArray(Charsets.US_ASCII))
            putInt(totalSize)
            put("WAVE".toByteArray(Charsets.US_ASCII))
            put("fmt ".toByteArray(Charsets.US_ASCII))
            putInt(16) // Subchunk1Size for PCM
            putShort(1.toShort()) // AudioFormat = PCM
            putShort(1.toShort()) // NumChannels = Mono
            putInt(sampleRate)
            putInt(sampleRate * 2) // ByteRate
            putShort(2.toShort()) // BlockAlign
            putShort(16.toShort()) // BitsPerSample
            put("data".toByteArray(Charsets.US_ASCII))
            putInt(dataSize)
        }

        val pcmBytes = ByteBuffer.allocate(dataSize).order(ByteOrder.LITTLE_ENDIAN)
        for (sample in pcm) {
            val clamped = max(-1.0f, min(1.0f, sample))
            val intSample = (clamped * 32767.0f).toInt().toShort()
            pcmBytes.putShort(intSample)
        }

        val outFile = File(outputPath)
        outFile.parentFile?.mkdirs()
        FileOutputStream(outFile).use { fos ->
            fos.write(header.array())
            fos.write(pcmBytes.array())
        }
    }

    fun close() {
        try {
            ortSession?.close()
        } catch (_: Exception) {
        }
        ortSession = null
        loadedModelPath = null
    }
}
