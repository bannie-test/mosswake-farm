#!/usr/bin/env python3
"""Placeholder sound effects for M1 (GDD section 17, M1 task "placeholder audio").
Short synthesised tones, written as 16-bit mono WAV to game/assets/audio. Final audio is M5.

Usage: python3 tools/gen_placeholder_audio.py
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "assets", "audio"))


def tone(freqs, seconds, volume=0.35, noise=0.0, slide=0.0):
    """Notes played one after another, each with a quick attack and a soft decay."""
    rng = random.Random(1)
    out = []
    per = int(RATE * seconds / len(freqs))
    for f in freqs:
        for i in range(per):
            t = i / RATE
            env = min(1.0, i / (0.005 * RATE)) * math.exp(-4.0 * i / per)
            freq = f * (1.0 + slide * i / per)
            s = math.sin(2 * math.pi * freq * t) * (1 - noise) + (rng.uniform(-1, 1) * noise)
            out.append(volume * env * s)
    return out


def write(name, samples):
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32767)) for s in samples))


SOUNDS = {
    "till": tone([150], 0.12, noise=0.7),
    "plant": tone([330, 440], 0.12),
    "water": tone([700], 0.22, volume=0.25, noise=0.5, slide=-0.4),
    "harvest": tone([523, 659, 784], 0.2),
    "merge_success": tone([523, 659, 784, 1047], 0.4),
    "merge_fail": tone([180], 0.3, volume=0.22, noise=0.6, slide=-0.3),      # a soft puff
    "coin": tone([988, 1319], 0.18),
    "level_up": tone([392, 523, 659, 784, 1047], 0.6),
    "ui_click": tone([600], 0.05, volume=0.2),
}

def music(notes, beat, wave_mix, bass, volume=0.22):
    """A short looping tune: a pentatonic melody over a soft bass note per bar. `notes` are
    (semitones above A3, beats) pairs; None is a rest."""
    out = []
    total_beats = sum(b for _, b in notes)
    n_total = int(RATE * beat * total_beats)
    pos = 0
    for semi, beats in notes:
        n = int(RATE * beat * beats)
        f = 220.0 * 2 ** (semi / 12.0) if semi is not None else 0.0
        for i in range(n):
            t = i / RATE
            env = min(1.0, i / (0.02 * RATE)) * math.exp(-2.2 * i / n) if f else 0.0
            tone_ = math.sin(2 * math.pi * f * t) * (1 - wave_mix) + (2 / math.pi) * math.asin(math.sin(2 * math.pi * f * t)) * wave_mix
            bar = (pos + i) // int(RATE * beat * 4)
            bf = 110.0 * 2 ** (bass[bar % len(bass)] / 12.0)
            bi = (pos + i) % int(RATE * beat * 4)
            benv = min(1.0, bi / (0.05 * RATE)) * math.exp(-1.2 * bi / (RATE * beat * 4))
            out.append(volume * (env * tone_ + 0.6 * benv * math.sin(2 * math.pi * bf * (pos + i) / RATE)))
        pos += n
    fade = int(0.05 * RATE)                      # the last samples ease out so the loop does not click
    for i in range(fade):
        out[len(out) - 1 - i] *= i / fade
    return out


# A minor pentatonic steps: 0 3 5 7 10 12 15
DAY = [(12, 1), (15, 1), (17, 1), (15, 1), (12, 2), (10, 2), (7, 1), (10, 1), (12, 1), (10, 1), (7, 2), (5, 2),
       (3, 1), (5, 1), (7, 1), (10, 1), (12, 2), (15, 2), (12, 1), (10, 1), (7, 1), (5, 1), (7, 3), (None, 1)]
NIGHT = [(0, 2), (3, 2), (7, 3), (None, 1), (5, 2), (3, 2), (0, 3), (None, 1), (7, 2), (10, 2), (12, 3), (None, 1), (10, 2), (7, 2), (5, 3), (None, 1)]
SOUNDS["music_day"] = music(DAY, 0.5, 0.35, [0, 0, 5, 5, 3, 3, 7, 0])
SOUNDS["music_night"] = music(NIGHT, 0.75, 0.1, [0, 5, 3, 0, 7, 5, 3, 0], volume=0.18)
SOUNDS["dig"] = tone([120, 90], 0.16, noise=0.75)
SOUNDS["scrub"] = tone([900], 0.12, volume=0.18, noise=0.85)
SOUNDS["awaken"] = tone([392, 494, 587, 784, 988], 0.9, volume=0.3)

if __name__ == "__main__":
    for name, samples in SOUNDS.items():
        write(name, samples)
    print(f"{len(SOUNDS)} sounds written to game/assets/audio")
