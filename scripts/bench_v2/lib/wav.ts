// Minimal WAV (RIFF/PCM) utilities: parse a WAV, read its duration, and
// concatenate several same-format WAV clips into one file. Bulbul TTS returns
// 16-bit PCM WAV, so we only need to support that.

export interface WavFormat {
  audioFormat: number; // 1 = PCM
  numChannels: number;
  sampleRate: number;
  bitsPerSample: number;
}

export interface ParsedWav {
  format: WavFormat;
  data: Uint8Array; // raw PCM samples (the "data" chunk payload)
}

function readAscii(bytes: Uint8Array, offset: number, len: number): string {
  return String.fromCharCode(...bytes.slice(offset, offset + len));
}

/** Parse a WAV file's format block and PCM payload. */
export function parseWav(bytes: Uint8Array): ParsedWav {
  if (readAscii(bytes, 0, 4) !== "RIFF" || readAscii(bytes, 8, 4) !== "WAVE") {
    throw new Error("Not a RIFF/WAVE file.");
  }

  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  let format: WavFormat | null = null;
  let data: Uint8Array | null = null;

  // Chunks start right after the 12-byte RIFF header.
  let offset = 12;
  while (offset + 8 <= bytes.length) {
    const id = readAscii(bytes, offset, 4);
    const size = view.getUint32(offset + 4, true);
    const body = offset + 8;

    if (id === "fmt ") {
      format = {
        audioFormat: view.getUint16(body, true),
        numChannels: view.getUint16(body + 2, true),
        sampleRate: view.getUint32(body + 4, true),
        bitsPerSample: view.getUint16(body + 14, true),
      };
    } else if (id === "data") {
      data = bytes.slice(body, body + size);
    }

    // Chunks are word-aligned: pad odd sizes by one byte.
    offset = body + size + (size % 2);
  }

  if (!format) throw new Error("WAV missing fmt chunk.");
  if (!data) throw new Error("WAV missing data chunk.");
  return { format, data };
}

/** Duration in seconds of a parsed WAV. */
export function wavDurationSeconds(wav: ParsedWav): number {
  const { sampleRate, numChannels, bitsPerSample } = wav.format;
  const byteRate = sampleRate * numChannels * (bitsPerSample / 8);
  if (byteRate === 0) return 0;
  return wav.data.length / byteRate;
}

/** Duration in seconds straight from raw WAV bytes. */
export function durationOfBytes(bytes: Uint8Array): number {
  return wavDurationSeconds(parseWav(bytes));
}

/** Build a valid WAV file from a format + raw PCM payload. */
export function encodeWav(format: WavFormat, data: Uint8Array): Uint8Array {
  const { numChannels, sampleRate, bitsPerSample } = format;
  const blockAlign = numChannels * (bitsPerSample / 8);
  const byteRate = sampleRate * blockAlign;

  const out = new Uint8Array(44 + data.length);
  const view = new DataView(out.buffer);
  const writeAscii = (offset: number, s: string) => {
    for (let i = 0; i < s.length; i++) out[offset + i] = s.charCodeAt(i);
  };

  writeAscii(0, "RIFF");
  view.setUint32(4, 36 + data.length, true);
  writeAscii(8, "WAVE");
  writeAscii(12, "fmt ");
  view.setUint32(16, 16, true); // PCM fmt chunk size
  view.setUint16(20, 1, true); // audioFormat = PCM
  view.setUint16(22, numChannels, true);
  view.setUint32(24, sampleRate, true);
  view.setUint32(28, byteRate, true);
  view.setUint16(32, blockAlign, true);
  view.setUint16(34, bitsPerSample, true);
  writeAscii(36, "data");
  view.setUint32(40, data.length, true);
  out.set(data, 44);
  return out;
}

/**
 * Concatenate several WAV clips (assumed same format) into one WAV file.
 * Used to stitch per-utterance TTS output into a single consultation clip.
 */
export function concatWavs(clips: Uint8Array[]): Uint8Array {
  if (clips.length === 0) throw new Error("No clips to concatenate.");
  const parsed = clips.map(parseWav);
  const format = parsed[0].format;

  const total = parsed.reduce((sum, p) => sum + p.data.length, 0);
  const merged = new Uint8Array(total);
  let cursor = 0;
  for (const p of parsed) {
    merged.set(p.data, cursor);
    cursor += p.data.length;
  }
  return encodeWav(format, merged);
}
