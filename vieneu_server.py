import os
import io
from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

# Khởi tạo FastAPI
app = FastAPI(
    title="VieNeu-TTS API Server",
    description="API Chuyển văn bản thành giọng nói Tiếng Việt tự nhiên bằng VieNeu-TTS cho App Báo thức",
    version="1.0.0"
)

# Khởi tạo mô hình VieNeu-TTS
tts = None

@app.on_event("startup")
def load_model():
    global tts
    try:
        from vieneu import Vieneu
        print("Đang nạp mô hình VieNeu-TTS...")
        tts = Vieneu()
        print("Đã nạp xong mô hình VieNeu-TTS thành công!")
    except Exception as e:
        print(f"Cảnh báo: Chưa cài đặt vieneu SDK ({e}). Hãy chạy: pip install vieneu")

class TtsRequest(BaseModel):
    text: str

@app.get("/")
def home():
    return {
        "status": "online",
        "service": "VieNeu-TTS API Server",
        "guide": "Gửi POST /synthesize kèm JSON {'text': 'Nội dung cần đọc'} để nhận file âm thanh wav"
    }

@app.post("/synthesize")
def synthesize(req: TtsRequest):
    global tts
    if not req.text.strip():
        raise HTTPException(status_code=400, detail="Văn bản không được để trống")

    if tts is None:
        raise HTTPException(
            status_code=500,
            detail="Mô hình VieNeu-TTS chưa được khởi tạo. Hãy đảm bảo đã cài pip install vieneu"
        )

    try:
        # Tổng hợp giọng nói từ văn bản
        audio = tts.infer(text=req.text)

        # Lưu audio vào bộ đệm RAM để trả về qua mạng
        buffer = io.BytesIO()
        tts.save(audio, buffer)
        buffer.seek(0)

        return StreamingResponse(buffer, media_type="audio/wav")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi tổng hợp âm thanh: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    # Chạy server tại cổng 8000
    uvicorn.run(app, host="0.0.0.0", port=8000)
