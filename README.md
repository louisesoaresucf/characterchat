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

Libby lives in an ancient scroll laid on an old oak table. A candle, a quill in its inkwell, dried lavender and roses, a glowing phial and a brass key sit around it. The scroll fills the window's height:

- **Wide screens:** Libby's portrait and the sealed letter sit beside the writing.
- **Phones and tablets:** a compact header sits above the writing.

Details:

- **The portrait:** a watercolour painted in SVG by script, with a fixed seed so it looks the same on every visit.
- **The wake button:** a letter closed with a wax seal. Breaking the seal starts the download.
- **The writing:** visitors write on ruled lines in old print (IM Fell English). Libby answers in handwriting (Dancing Script) that soaks in like ink as the model writes.
- **Day and night:** the table follows the visitor's light or dark setting. The scroll stays parchment in both.

## Things to try

- **Poke Libby's portrait.** She giggles, smiles and twitches an ear. Once awake, she opens her eyes, blinks, glances down while she writes, and smiles when she finds you a book.
- **Click the things on the table:**
  - the candle turns day into night
  - the potion phial bubbles over and asks Libby for a surprise book
  - the quill flicks ink across the table
  - the flowers shed petals
  - the brass key opens a hidden drawer of secrets, some drawn from your database
- **Play "guess the book".** Write "play" or tap the suggestion. Libby hides a well-known book from the database and gives three clues: its tropes, the shape of its title, then its author's initials. Guessing on the first clue earns 3 gold stars, the second 2, the third 1. It needs no model, so you can play while Libby downloads. Your stars are remembered in this browser.
- **Turn on sound** with the speaker button. Pages rustle, the quill scratches as she writes, and chimes ring when the seal breaks or you guess right. Every sound is synthesised in the browser, with no audio files. Sound is off until you turn it on.

Sparkles and wiggles respect the "reduce motion" setting.

## Books: the gameofbooks database

Libby's library is `books/fantasy_novels.json`, a copy of the database from the [gameofbooks](https://github.com/louisesoaresucf/gameofbooks) recommendation game: 574 books and series from Wikipedia's *List of fantasy novels*, each with authors and trope tags. gameofbooks is the source of truth and is left unchanged. To update Libby after editing the database there:

```bash
tools/sync-books.sh
```

You can pass a local checkout instead: `tools/sync-books.sh ../gameofbooks`.

The database has no plot summaries, so Libby describes books only through their tropes. Small models misremember books, so the page doesn't trust the model's memory for titles and authors:

1. **Facts per message.** Only the books relevant to your message go into the prompt.
2. **Picked in code.** When you ask for a book (by mood, by author or "like The Hobbit"), the page chooses one by matching your words to the database's 29 tropes. Books marked `read` or `dnf` in your reading log are skipped. Libby's reply then starts with the true title and author, and the model only continues in her voice. "Who wrote…?" answers start the same way.
3. **Checked afterwards.** Wrong authors are corrected. Anything after a title that isn't in the database is cut. Web links and rambling extra paragraphs are removed.

Titles and authors are therefore reliable. Details about what happens inside a book can still be invented, especially by the lighter CPU model, so the page asks visitors to check a title before buying it. Books that aren't in the database are ones Libby says she doesn't know.

## Tuning

Everything that shapes the character is in the main `<script>` in `index.html`:

- `SYSTEM_PROMPT` and `EXAMPLE`: Libby's persona, her rules, and one example exchange that sets her tone and reply length.
- `MOODS`: the words that map to each trope (funny → humor, dark → grimdark, and so on).
- `STARTER_SHELF`: well-known books she offers when a message gives nothing to match on.
- `MAX_HISTORY_MESSAGES` (6, the last 3 exchanges): how much conversation she remembers. The worker also trims the oldest turns if the prompt passes about 1,800 tokens.
- `MAX_NEW_TOKENS` (100 on WebGPU, 72 on the CPU): the reply length cap. A reply cut off mid-sentence is trimmed back to its last full sentence.
