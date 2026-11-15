# Libby the Book Elf

A single-page chat with **Libraria ("Libby")**, a book elf with an ethereal, friendly voice and a love of fantasy literature. The language model runs entirely in the visitor's browser via [Transformers.js](https://github.com/huggingface/transformers.js) 4.3.2. Nothing is sent to a server.

## Run it

It's one static file. Serve the folder from any static host (GitHub Pages, Netlify, etc.) or run it locally:

```bash
python3 -m http.server 8080
```

Then open http://localhost:8080. Opening the file directly via `file://` won't work, because browsers block module workers there.

## Models

| Backend | Model | Quantization | Download |
|---|---|---|---|
| WebGPU (with `shader-f16`) | `onnx-community/LFM2-700M-ONNX` | q4f16 | ~500 MB |
| WebGPU (no `shader-f16`) | `onnx-community/LFM2-700M-ONNX` | q4 | ~563 MB |
| WASM fallback | `HuggingFaceTB/SmolLM2-360M-Instruct` | 8-bit | ~367 MB |

The browser downloads the model once and keeps it in its Cache Storage. Later visits load it from there.

The WASM build of onnxruntime-web can't run LFM2's quantized embedding layer (`GatherBlockQuantized`), so browsers without WebGPU get SmolLM2-360M. It's lighter and noticeably weaker at staying in character.

LFM2 is released under the LFM Open License v1.0. Check its terms before you use it commercially.

## Tuning

Everything that shapes the character is at the top of the main `<script>` in `index.html`:

- `SYSTEM_PROMPT`: Libby's persona plus a short "shelf" of real books. The shelf grounds her recommendations so a small model doesn't invent titles.
- `EXAMPLE`: one example exchange that anchors her tone and reply length.
- `MAX_HISTORY_MESSAGES` (6, the last 3 exchanges): how much conversation she remembers. The worker also trims the oldest turns if the prompt passes about 1,800 tokens.
- `MAX_NEW_TOKENS` (128): the reply length cap. A reply cut off mid-sentence is trimmed back to its last full sentence.
