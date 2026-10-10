"""Unlit ses efektlerini SIFIRDAN üretir (sentezler).

Neden kendimiz üretiyoruz? Başka uygulamaların (ör. Duolingo) seslerini
kullanmak telif hakkı sorunu olur. Bu sesler tamamen matematikle (sinüs
dalgaları + ses zarfı) üretildiği için bizim.

Çalıştırmak için (numpy gerekir):
    python3 tool/make_sounds.py
Çıktı: assets/sounds/*.wav  (22050 Hz, 16 bit, mono)
"""
import os
import wave

import numpy as np

RATE = 22050  # örnekleme hızı (Hz)
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')


def tone(freq, dur, attack=0.005, decay=None, harmonics=((1, 1.0),),
         glide_to=None):
    """Tek bir nota: [freq] Hz, [dur] saniye.

    attack: sesin yükselme süresi; decay: üstel sönme hızı (saniye).
    harmonics: (kat, şiddet) çiftleri; çan/zil tınısı için.
    glide_to: verilirse frekans bu değere doğru kayar (nefes sesleri için).
    """
    n = int(RATE * dur)
    t = np.arange(n) / RATE
    if glide_to is None:
        phase = 2 * np.pi * freq * t
    else:
        f = np.linspace(freq, glide_to, n)
        phase = 2 * np.pi * np.cumsum(f) / RATE
    wave_ = sum(amp * np.sin(k * phase) for k, amp in harmonics)
    env = np.minimum(1.0, t / attack) if attack > 0 else np.ones(n)
    if decay is not None:
        env = env * np.exp(-t / decay)
    # Sonda tıkırtı olmasın diye kısa bir kısılma
    fade = min(n, int(RATE * 0.02))
    env[-fade:] *= np.linspace(1, 0, fade)
    return wave_ * env


def mix(parts, total):
    """(başlangıç saniyesi, ses) parçalarını tek bir kayıtta birleştirir."""
    out = np.zeros(int(RATE * total))
    for start, part in parts:
        i = int(RATE * start)
        j = min(len(out), i + len(part))
        out[i:j] += part[: j - i]
    return out


def save(name, samples, peak=0.6):
    """Ses seviyesini ayarlayıp WAV olarak kaydeder."""
    samples = samples / (np.max(np.abs(samples)) + 1e-9) * peak
    data = (samples * 32767).astype('<i2').tobytes()
    path = os.path.join(OUT, name)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data)
    print(f'{name}: {len(samples) / RATE:.2f} sn, {os.path.getsize(path)} bayt')


BELL = ((1, 1.0), (2, 0.35), (3, 0.12))  # parlak, zil gibi tını
SOFT = ((1, 1.0), (2, 0.15))  # yumuşak tını

# Not frekansları (Hz)
C5, E5, G5, A5 = 523.25, 659.25, 783.99, 880.00
C6, E6, G6, A6 = 1046.50, 1318.51, 1567.98, 1760.00
G4, D5 = 392.00, 587.33

os.makedirs(OUT, exist_ok=True)

# Görev tamamlandı: kısa, parlak "ding-ding" (yükselen iki nota)
save('success.wav', mix([
    (0.00, tone(E6, 0.18, decay=0.08, harmonics=BELL)),
    (0.09, tone(A6, 0.40, decay=0.16, harmonics=BELL)),
], 0.50))

# Büyük kutlama: yükselen arpej (do-mi-sol-do) + parıltı
save('fanfare.wav', mix([
    (0.00, tone(C5, 0.30, decay=0.12, harmonics=BELL)),
    (0.08, tone(E5, 0.30, decay=0.12, harmonics=BELL)),
    (0.16, tone(G5, 0.30, decay=0.12, harmonics=BELL)),
    (0.24, tone(C6, 0.70, decay=0.30, harmonics=BELL)),
    (0.24, tone(E6, 0.70, decay=0.25, harmonics=SOFT) * 0.5),
    (0.40, tone(G6, 0.45, decay=0.15, harmonics=SOFT) * 0.35),
], 1.00))

# Sakin an: alçak, yumuşak bir çan (suçlamasız, sıcak)
save('calm.wav', mix([
    (0.00, tone(G4, 0.90, attack=0.03, decay=0.35, harmonics=SOFT)),
    (0.10, tone(D5, 0.80, attack=0.03, decay=0.30, harmonics=SOFT) * 0.6),
], 1.00), peak=0.45)

# Nefes al / ver: çok yumuşak, kayan tonlar (göz kapalıyken ipucu)
save('breath_in.wav', tone(330, 0.70, attack=0.30, decay=0.6,
                           harmonics=SOFT, glide_to=440), peak=0.3)
save('breath_out.wav', tone(440, 0.70, attack=0.30, decay=0.6,
                            harmonics=SOFT, glide_to=330), peak=0.3)

# Erteleme süresi doldu: iki tonlu tatlı zil
save('bell.wav', mix([
    (0.00, tone(A5, 1.10, decay=0.40, harmonics=BELL)),
    (0.18, tone(E6, 1.00, decay=0.35, harmonics=BELL) * 0.7),
], 1.30))
