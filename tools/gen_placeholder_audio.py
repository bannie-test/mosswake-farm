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

if __name__ == "__main__":
    for name, samples in SOUNDS.items():
        write(name, samples)
    print(f"{len(SOUNDS)} placeholder sounds written to game/assets/audio")
