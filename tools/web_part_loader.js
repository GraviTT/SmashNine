// Joins build files that tools/build_web.ps1 split into <name>.part0, .part1, ... Some static
// hosts (ChatGPT Sites: "artifacts_git_receive_pack_object_too_large") reject single files as
// big as the Godot engine. Godot's loader asks for index.wasm and index.pck with fetch(); this
// answers with one streamed response, so its progress bar and wasm streaming still work.
// build_web.ps1 gzips each file before splitting it (2026-11-24): hosts send unknown .partN files
// as plain bytes, so without that the 39.5 MB engine travelled uncompressed (10.1 MB gzipped).
// The joined parts are gunzipped here; parts that are not gzip (an older build) pass through.
// build_web.ps1 replaces the PARTS placeholder with {"<file>": <part count>, ...} and inlines
// this script in index.html before index.js.
(function () {
	const parts = /*PARTS*/{};
	const types = { 'index.wasm': 'application/wasm' };
	const realFetch = window.fetch.bind(window);

	// Every part starts downloading now; their bodies are passed on in order.
	function joinParts(name, url, init, count) {
		const pending = [];
		for (let i = 0; i < count; i++) {
			pending.push(realFetch(`${url.pathname}.part${i}${url.search}`, init));
		}
		let index = 0;
		let reader = null;
		return new ReadableStream({
			async pull(controller) {
				for (;;) {
					if (!reader) {
						if (index >= count) {
							controller.close();
							return;
						}
						const response = await pending[index];
						if (!response.ok) {
							throw new Error(`Failed loading ${name}.part${index} (${response.status})`);
						}
						index += 1;
						reader = response.body.getReader();
					}
					const chunk = await reader.read();
					if (chunk.done) {
						reader = null;
						continue;
					}
					controller.enqueue(chunk.value);
					return;
				}
			},
		});
	}

	// Looks at the first two bytes: gzip (1f 8b) is unpacked, anything else is passed on as it is.
	// Neither file starts like gzip by itself (the wasm starts with "\0asm", the pck with "GDPC").
	async function gunzipIfPacked(name, stream) {
		const reader = stream.getReader();
		const head = [];
		let length = 0;
		while (length < 2) {
			const chunk = await reader.read();
			if (chunk.done) {
				break;
			}
			head.push(chunk.value);
			length += chunk.value.length;
		}
		const first = new Uint8Array(length);
		let at = 0;
		for (const piece of head) {
			first.set(piece, at);
			at += piece.length;
		}
		const whole = new ReadableStream({
			start(controller) {
				if (first.length > 0) {
					controller.enqueue(first);
				}
			},
			async pull(controller) {
				const chunk = await reader.read();
				if (chunk.done) {
					controller.close();
					return;
				}
				controller.enqueue(chunk.value);
			},
			cancel(reason) {
				return reader.cancel(reason);
			},
		});
		if (first.length < 2 || first[0] !== 0x1f || first[1] !== 0x8b) {
			return whole;
		}
		if (typeof DecompressionStream === 'undefined') {
			throw new Error(`This browser cannot unpack ${name} (it has no DecompressionStream); please update it`);
		}
		return whole.pipeThrough(new DecompressionStream('gzip'));
	}

	window.fetch = function (input, init) {
		const url = new URL(typeof input === 'string' ? input : input.url, window.location.href);
		const name = url.pathname.split('/').pop();
		const count = parts[name];
		if (!count) {
			return realFetch(input, init);
		}
		return gunzipIfPacked(name, joinParts(name, url, init, count)).then((body) => new Response(body, {
			status: 200,
			headers: { 'Content-Type': types[name] || 'application/octet-stream' },
		}));
	};
}());
