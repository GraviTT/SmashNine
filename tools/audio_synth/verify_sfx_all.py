"""Re-read delivered WAVs, independently check PCM metrics, replay all in RAM."""
import hashlib
import json
import wave
from collections import Counter

import numpy as np
from PIL import Image, ImageDraw
import synth
import sfx_all as full


def level(x):
    return float(20 * np.log10(max(float(x), 1e-12)))


def main():
    manifest = json.loads((full.REPORT / 'measurements.json').read_text(encoding='utf-8'))
    records = manifest['records']
    catalog = full.catalog()
    expected = {f'{sound}-{style}.wav' for sound in catalog for style in 'abc'}
    actual = {p.name for p in full.OUT.glob('*.wav') if not p.name.startswith('music_')}
    assert actual == expected, (actual - expected, expected - actual)
    assert len(records) == len(expected)
    assert len({r['file'] for r in records}) == len(expected)
    trial = json.loads((full.ROOT / 'reports/codex-aud-01a/measurements.json').read_text(encoding='utf-8'))
    trial_sha = {r['file']: r['sha256'] for r in trial['records']}
    details, hashes = [], []
    for m in records:
        sound, style = m['sound'], m['style']
        path = full.ROOT / m['file']
        with wave.open(str(path), 'rb') as w:
            assert (w.getframerate(), w.getsampwidth(), w.getnchannels(), w.getcomptype()) == (44100, 2, 1, 'NONE')
            raw = w.readframes(w.getnframes())
        pcm = np.frombuffer(raw, '<i2')
        y = pcm.astype(np.float64) / 32768
        peak, rms = level(max(abs(y))), level(np.sqrt(np.mean(y ** 2)))
        duration = len(y) / 44100
        assert peak <= (-.9998 if sound in full.TRIAL else -1)
        assert not np.any((pcm == 32767) | (pcm == -32768))
        assert abs(peak - m['peak_dbfs']) < 1e-8 and abs(rms - m['rms_dbfs']) < 1e-8
        target = full.TRIAL[sound][3] if sound in full.TRIAL else full.SPECS[sound][2]
        assert abs(rms - target) < .02 and abs(duration - m['length_s']) < 1e-8
        assert m['duration_range_s'][0] - 1 / 44100 <= duration <= m['duration_range_s'][1] + 1 / 44100
        lead = float(np.flatnonzero(abs(y) > .001)[0] / 44100 * 1000)
        tail_peak = level(max(abs(y[-44:])))
        tail_step = float(max(abs(np.diff(y[-45:]))))
        assert lead <= 5 and pcm[0] == pcm[-1] == 0
        assert tail_peak < -45 and tail_step < .001
        sha = hashlib.sha256(path.read_bytes()).hexdigest()
        assert sha == m['sha256']
        if sound in full.TRIAL:
            assert sha == trial_sha[m['file']]
            regenerated, _ = synth.master(getattr(synth, f'{sound}_{style}')(duration=duration), target)
        else:
            regenerated, _ = full.master(full.render_raw(sound, style), target)
        assert regenerated.tobytes() == raw, f'Non-deterministic {path.name}'
        power = abs(np.fft.rfft(y)) ** 2
        freq = np.fft.rfftfreq(len(y), 1 / 44100)
        details.append({'file': path.name, 'sound': sound, 'style': style, 'group': m['group'],
                        'peak_dbfs': peak, 'rms_dbfs': rms, 'length_s': duration,
                        'lead_in_ms_at_minus60': lead, 'last_1ms_peak_dbfs': tail_peak,
                        'last_1ms_max_step': tail_step, 'dc_dbfs': level(abs(np.mean(y))),
                        'power_centroid_hz': float(np.sum(power * freq) / power.sum()),
                        'energy_30_120hz_fraction': float(power[(freq >= 30) & (freq < 120)].sum() / power.sum()),
                        'energy_above_4khz_fraction': float(power[freq >= 4000].sum() / power.sum()),
                        'deterministic_pcm': True, 'preserved_trial': sound in full.TRIAL})
        hashes.append(sha)
        with Image.open(full.REPORT / f'{sound}.png') as im:
            assert im.size == (1536, 700); im.verify()
    assert len(set(hashes)) == len(hashes), 'Accidental duplicate audio'
    spreads = {}
    for sound in catalog:
        trio = [m for m in details if m['sound'] == sound]
        assert {m['style'] for m in trio} == set('abc') and len(trio) == 3
        spreads[sound] = max(m['rms_dbfs'] for m in trio) - min(m['rms_dbfs'] for m in trio)
        assert spreads[sound] < .02
    summary = {
        'status': 'PASS', 'id_count': len(catalog), 'wav_count': len(details),
        'new_wav_count': sum(not d['preserved_trial'] for d in details), 'preserved_trial_wav_count': len(trial_sha),
        'figure_count': len(catalog), 'ids_per_group': dict(Counter(r['group'] for r in catalog.values())),
        'max_rms_spread_db': max(spreads.values()),
        'max_onset_ms': max(d['lead_in_ms_at_minus60'] for d in details),
        'loudest_tail_1ms_dbfs': max(d['last_1ms_peak_dbfs'] for d in details),
        'largest_tail_step_fs': max(d['last_1ms_max_step'] for d in details),
        'peak_new_max_dbfs': max(d['peak_dbfs'] for d in details if not d['preserved_trial']),
        'peak_trial_max_dbfs': max(d['peak_dbfs'] for d in details if d['preserved_trial']),
        'rms_spread_db_by_sound': spreads, 'details': details,
        'checks': ['Exact non-music catalog coverage', 'PCM16 mono 44100Hz', 'zero clipped samples',
                   'new sample peak <= -1dBFS; preserved trial quantization tolerance 0.0002dB',
                   'same-id A/B/C RMS spread < .02dB', 'onset <=5ms at -60dBFS', 'zero endpoints',
                   'tail1ms <-45dBFS and max sample step <.001FS', '216 deterministic PCM replays',
                   '36 trial WAV SHA256 unchanged', 'all WAVs distinct', '72 trio PNGs readable'],
        'limitations': ['No listening judgment', 'No LUFS or oversampled true-peak measurement',
                        'No game integration or simultaneous-voice mix test', 'Noise and FM labels describe synthesis intent']}
    (full.REPORT / 'verification.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
    # Group-level picture: actual full-file RMS, not subjective loudness.
    im = Image.new('RGB', (1280, 680), '#0e1523'); d = ImageDraw.Draw(im)
    d.text((34, 22), 'AUD-01 / 72 IDs x A B C / 216 measured WAVs', font=synth.font(29), fill='white')
    d.text((34, 68), '180 new + 36 trial preserved / sample peak <= -1dBFS* / clipping: 0', font=synth.font(19), fill='#83e2c3')
    left, right = 430, 1170
    for tick in [-30, -25, -20, -15, -10]:
        xx = left + (tick + 30) / 20 * (right - left)
        d.line((xx, 130, xx, 540), fill='#2e3a51')
        d.text((xx - 20, 548), str(tick), font=synth.font(16), fill='#a9b8ce')
    for i, group in enumerate(full.GROUPS):
        yy = 150 + i * 64
        rows = [r for r in details if r['group'] == group]
        low, high = min(r['rms_dbfs'] for r in rows), max(r['rms_dbfs'] for r in rows)
        d.text((34, yy - 13), f'{group:12s} {len(rows)//3:2d} IDs / {len(rows):2d} WAV', font=synth.font(20), fill='white')
        xx = lambda v: left + (v + 30) / 20 * (right - left)
        d.line((xx(low), yy, xx(high), yy), fill='#83e2c3', width=8)
        for r in rows[::3]:
            x = xx(r['rms_dbfs']); d.ellipse((x - 4, yy - 4, x + 4, yy + 4), fill='#ffc38c')
        d.text((xx(high) + 12, yy - 10), f'{low:.1f}..{high:.1f}', font=synth.font(17), fill='#cbd7ed')
    d.text((34, 590), 'Full-file RMS dBFS / A-B-C matched per ID. Human listening still required.', font=synth.font(19), fill='#a9b8ce')
    d.text((34, 625), '*Unchanged trial peak: -0.99985dBFS (PCM rounding); new peak ceiling: -1.00015dBFS.', font=synth.font(17), fill='#a9b8ce')
    im.save(full.REPORT / 'loudness-overview.png')
    print(json.dumps({k: v for k, v in summary.items() if k not in ('details', 'rms_spread_db_by_sound', 'checks', 'limitations')}, indent=2))


if __name__ == '__main__':
    main()
