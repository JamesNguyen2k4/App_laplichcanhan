#include <jni.h>
#include <android/log.h>
#include <string>
#include <vector>
#include <mutex>
#include <cstring>
#include <algorithm>
#include <thread>
#include "llama.h"

#define TAG "VieNeuLlamaJNI"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

static std::mutex g_llama_mutex;
static llama_model * g_model = nullptr;
static std::string g_loaded_model_path;
static bool g_backend_initialized = false;

static void ensure_backend() {
    if (!g_backend_initialized) {
        llama_backend_init();
        g_backend_initialized = true;
    }
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_example_duan_1len_1lich_1ca_1nhan_LlamaBridge_generateSpeechTokens(
    JNIEnv * env,
    jobject /* this */,
    jstring jModelPath,
    jstring jPrompt,
    jint maxTokens,
    jfloat temperature,
    jint topK
) {
    std::lock_guard<std::mutex> lock(g_llama_mutex);
    ensure_backend();

    const char * cModelPath = env->GetStringUTFChars(jModelPath, nullptr);
    const char * cPrompt = env->GetStringUTFChars(jPrompt, nullptr);
    std::string modelPath(cModelPath ? cModelPath : "");
    std::string prompt(cPrompt ? cPrompt : "");
    if (cModelPath) env->ReleaseStringUTFChars(jModelPath, cModelPath);
    if (cPrompt) env->ReleaseStringUTFChars(jPrompt, cPrompt);

    if (modelPath.empty() || prompt.empty()) {
        return env->NewStringUTF("");
    }

    // Nạp model GGUF nếu chưa nạp hoặc đổi đường dẫn
    if (g_model == nullptr || g_loaded_model_path != modelPath) {
        if (g_model != nullptr) {
            llama_model_free(g_model);
            g_model = nullptr;
        }
        llama_model_params model_params = llama_model_default_params();
        model_params.n_gpu_layers = 0; // CPU mode trên Android
        g_model = llama_model_load_from_file(modelPath.c_str(), model_params);
        if (g_model == nullptr) {
            LOGE("Không thể tải model GGUF từ: %s", modelPath.c_str());
            return env->NewStringUTF("");
        }
        g_loaded_model_path = modelPath;
        LOGI("Đã nạp thành công GGUF model: %s", modelPath.c_str());
    }

    const llama_vocab * vocab = llama_model_get_vocab(g_model);

    // Tokenize prompt (bật parse_special = true để nhận diện <|TEXT_PROMPT_START|>, <|speech_X|>...)
    int n_prompt = -llama_tokenize(vocab, prompt.c_str(), (int32_t)prompt.size(), nullptr, 0, true, true);
    if (n_prompt <= 0) {
        LOGE("Lỗi tokenize prompt (n_prompt=%d)", n_prompt);
        return env->NewStringUTF("");
    }

    std::vector<llama_token> prompt_tokens(n_prompt);
    if (llama_tokenize(vocab, prompt.c_str(), (int32_t)prompt.size(), prompt_tokens.data(), n_prompt, true, true) < 0) {
        LOGE("Tokenize prompt thất bại");
        return env->NewStringUTF("");
    }

    // Khởi tạo context
    llama_context_params ctx_params = llama_context_default_params();
    int32_t n_ctx_needed = n_prompt + maxTokens + 64;
    ctx_params.n_ctx = std::max(2048, n_ctx_needed);
    ctx_params.n_batch = std::max(512, n_prompt);
    int hw_threads = (int)std::thread::hardware_concurrency();
    int n_threads = std::max(2, std::min(4, hw_threads > 0 ? hw_threads : 4));
    ctx_params.n_threads = n_threads;
    ctx_params.n_threads_batch = n_threads;

    llama_context * ctx = llama_init_from_model(g_model, ctx_params);
    if (ctx == nullptr) {
        LOGE("Không thể tạo llama_context");
        return env->NewStringUTF("");
    }

    // Tạo sampler (top_k + temp + dist)
    auto sparams = llama_sampler_chain_default_params();
    llama_sampler * smpl = llama_sampler_chain_init(sparams);
    llama_sampler_chain_add(smpl, llama_sampler_init_top_k(topK > 0 ? topK : 50));
    llama_sampler_chain_add(smpl, llama_sampler_init_temp(temperature > 0.0f ? temperature : 1.0f));
    llama_sampler_chain_add(smpl, llama_sampler_init_dist(LLAMA_DEFAULT_SEED));

    // Đánh giá prompt ban đầu
    llama_batch batch = llama_batch_get_one(prompt_tokens.data(), (int32_t)prompt_tokens.size());
    if (llama_decode(ctx, batch) != 0) {
        LOGE("llama_decode thất bại trên prompt");
        llama_sampler_free(smpl);
        llama_free(ctx);
        return env->NewStringUTF("");
    }

    std::string output_text;
    const std::string stop_token = "<|SPEECH_GENERATION_END|>";

    for (int i = 0; i < maxTokens; ++i) {
        llama_token new_token_id = llama_sampler_sample(smpl, ctx, -1);

        if (llama_vocab_is_eog(vocab, new_token_id)) {
            break;
        }

        char buf[256];
        int n = llama_token_to_piece(vocab, new_token_id, buf, sizeof(buf), 0, true);
        if (n > 0) {
            output_text.append(buf, n);
            size_t stop_pos = output_text.find(stop_token);
            if (stop_pos != std::string::npos) {
                output_text.erase(stop_pos);
                break;
            }
        }

        llama_batch next_batch = llama_batch_get_one(&new_token_id, 1);
        if (llama_decode(ctx, next_batch) != 0) {
            LOGE("llama_decode thất bại ở bước %d", i);
            break;
        }
    }

    llama_sampler_free(smpl);
    llama_free(ctx);

    // Lọc chỉ giữ ký tự ASCII in được (speech tokens luôn ở dạng <|speech_12345|>)
    // Tránh 100% lỗi JNI DETECTED ERROR IN APPLICATION: input is not valid Modified UTF-8
    std::string safe_ascii;
    safe_ascii.reserve(output_text.size());
    for (unsigned char ch : output_text) {
        if (ch >= 0x20 && ch <= 0x7E) {
            safe_ascii.push_back((char)ch);
        }
    }

    return env->NewStringUTF(safe_ascii.c_str());
}

extern "C" JNIEXPORT void JNICALL
Java_com_example_duan_1len_1lich_1ca_1nhan_LlamaBridge_freeModel(
    JNIEnv * /* env */,
    jobject /* this */
) {
    std::lock_guard<std::mutex> lock(g_llama_mutex);
    if (g_model != nullptr) {
        llama_model_free(g_model);
        g_model = nullptr;
        g_loaded_model_path.clear();
    }
}
