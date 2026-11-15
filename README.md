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

## Design

Libby lives in an ancient scroll: wooden rollers, worn parchment and an ink-drawn portrait of her (an SVG, drawn by script with a fixed seed so she looks the same on every visit). Visitors write on ruled lines in old print (IM Fell English). Libby answers in handwriting (Dancing Script) that soaks into the page like ink as the model writes. The room around the scroll follows the visitor's light or dark setting, and the scroll stays parchment in both.

## Book facts

Small models misremember books, so the page doesn't trust the model's memory for titles and authors:

1. **Catalog.** `CATALOG` holds about 100 real fantasy books, each with author, year, series and a one-line summary. Each message adds only the relevant entries to the prompt, which keeps the context short.
2. **Picked in code.** When you ask for a book (by mood, by author or "like The Hobbit"), the page picks one from the catalog and starts Libby's reply with its true title and author. The model only continues in her voice. "Who wrote…?" answers are started the same way.
3. **Checked afterwards.** `finalize()` corrects wrong authors and publication years for catalog books. It cuts the reply before any title that isn't in the catalog, and adds a margin note if one remains.

Facts about what happens inside a book can still slip, especially in the lighter WASM model, so the page asks visitors to check a title before buying it.

## Tuning

Everything that shapes the character is in the main `<script>` in `index.html`:

- `SYSTEM_PROMPT`: Libby's persona and rules.
- `EXAMPLE`: one example exchange that anchors her tone and reply length.
- `CATALOG`, `MOODS`: the books she knows and the moods she can match (funny, cozy, dragons, dark, wizards…). Add a book by adding a row.
- `MAX_HISTORY_MESSAGES` (6, the last 3 exchanges): how much conversation she remembers. The worker also trims the oldest turns if the prompt passes about 1,800 tokens.
- `MAX_NEW_TOKENS` (128): the reply length cap. A reply cut off mid-sentence is trimmed back to its last full sentence.
