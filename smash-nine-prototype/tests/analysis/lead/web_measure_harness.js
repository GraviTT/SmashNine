// Quality track 4 (2026-11-27), web measurement builds only (never deployed): goes into the
// build's index.html as a script element of its own, before the one that loads index.js.
// A hidden Browser pane runs no requestAnimationFrame, so a Worker timer stands in for the
// display: a frame every 1/60 s, and a frame that runs long makes the next one wait for the
// next 1/60 s boundary, as a 60 Hz display would. Every main-loop iteration (all callbacks of
// one tick) is timed into window.__frames in milliseconds: physics steps, scripts, and handing
// the frame to WebGL; the GPU's own time is not in it.
// web_frame_measure.gd marks its stretch (window.__mark_start, __mark_end) and writes what each
// iteration held (window.__meta); window.__summary() gives P50/P95/P99 per group, the same
// groups as frame_time_probe.gd, plus how often a frame ran more than one physics step.
(function () {
	const source = [
		"const start = performance.now(); let frame = 0;",
		"function schedule() {",
		"  const now = performance.now();",
		"  frame = Math.max(frame + 1, Math.ceil((now - start) * 60 / 1000));",
		"  setTimeout(function () { postMessage(0); }, Math.max(0, start + frame * 1000 / 60 - now));",
		"}",
		"onmessage = schedule;",
		"schedule();",
	].join("\n");
	const pump = new Worker(URL.createObjectURL(new Blob([source], { type: "text/javascript" })));
	let waiting = [];
	let nextId = 1;
	window.__frames = [];
	pump.onmessage = function () {
		const run = waiting;
		waiting = [];
		const now = performance.now();
		let spent = 0;
		let ran = 0;
		for (const entry of run) {
			if (entry.cancelled) {
				continue;
			}
			const begin = performance.now();
			entry.callback(now);
			spent += performance.now() - begin;
			ran += 1;
		}
		if (ran > 0) {
			window.__frames.push(spent);
		}
		pump.postMessage(0);
	};
	window.requestAnimationFrame = function (callback) {
		const entry = { id: nextId++, callback: callback, cancelled: false };
		waiting.push(entry);
		return entry.id;
	};
	window.cancelAnimationFrame = function (id) {
		for (const entry of waiting) {
			if (entry.id === id) {
				entry.cancelled = true;
			}
		}
	};
	window.__summary = function () {
		const start = window.__mark_start;
		const end = window.__mark_end;
		const meta = window.__meta || [];
		const n = Math.min(meta.length, end - start);
		const pick = function (values) {
			if (values.length === 0) {
				return { n: 0 };
			}
			const sorted = values.slice().sort(function (a, b) { return a - b; });
			const at = function (p) { return Math.round(sorted[Math.min(Math.floor(p * sorted.length), sorted.length - 1)] * 100) / 100; };
			const mean = sorted.reduce(function (a, b) { return a + b; }, 0) / sorted.length;
			return { n: sorted.length, p50: at(0.5), p95: at(0.95), p99: at(0.99), max: at(1), mean: Math.round(mean * 100) / 100 };
		};
		// per_step: a frame's time over the physics steps it ran, for frames with any (desktop
		// numbers are per physics step: one step a frame under --fixed-fps).
		const groups = { all: [], per_step: [], alive_12_plus: [], alive_6_to_11: [], alive_2_to_5: [], panel_refresh_frames: [], other_frames: [], one_step: [], more_steps: [] };
		const step_counts = {};
		let more = 0;
		let none = 0;
		for (let j = 0; j < n; j++) {
			const ms = window.__frames[start + j];
			const alive = meta[j][0];
			const phase = meta[j][1];
			const steps = meta[j][2];
			const refreshed = meta[j][3];
			groups.all.push(ms);
			step_counts[steps] = (step_counts[steps] || 0) + 1;
			if (steps > 0) {
				groups.per_step.push(ms / steps);
			}
			if (alive >= 12) {
				groups.alive_12_plus.push(ms);
			} else if (alive >= 6) {
				groups.alive_6_to_11.push(ms);
			} else if (alive >= 2) {
				groups.alive_2_to_5.push(ms);
			}
			(refreshed ? groups.panel_refresh_frames : groups.other_frames).push(ms);
			if (steps === 1) {
				groups.one_step.push(ms);
			} else if (steps > 1) {
				groups.more_steps.push(ms);
				more += 1;
			} else {
				none += 1;
			}
			const key = "phase " + phase;
			(groups[key] = groups[key] || []).push(ms);
		}
		const out = { build: window.__build, iterations: n, page_iterations: end - start, meta_iterations: meta.length, more_step_iterations: more, zero_step_iterations: none, step_counts: step_counts, groups: {} };
		for (const key in groups) {
			out.groups[key] = pick(groups[key]);
		}
		return out;
	};
})();
