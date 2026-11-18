package com.example.duan_len_lich_ca_nhan

object LlamaBridge {
    init {
        System.loadLibrary("vieneu_llama")
    }

    external fun generateSpeechTokens(
        modelPath: String,
        prompt: String,
        maxTokens: Int,
        temperature: Float,
        topK: Int
    ): String

    external fun freeModel()
}
