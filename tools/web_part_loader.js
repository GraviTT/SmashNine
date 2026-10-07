// Joins build files that tools/build_web.ps1 split into <name>.part0, .part1, ... Some static
// hosts (ChatGPT Sites: "artifacts_git_receive_pack_object_too_large") reject single files as
// big as the Godot engine. Godot's loader asks for index.wasm and index.pck with fetch(); this
// answers with one streamed response, so its progress bar and wasm streaming still work.
// build_web.ps1 replaces the PARTS placeholder with {"<file>": <part count>, ...} and inlines
// this script in index.html before index.js.
(function () {
	const parts = /*PARTS*/{};
	const types = { 'index.wasm': 'application/wasm' };
	const realFetch = window.fetch.bind(window);

	window.fetch = function (input, init) {
		const url = new URL(typeof input === 'string' ? input : input.url, window.location.href);
		const name = url.pathname.split('/').pop();
		const count = parts[name];
		if (!count) {
			return realFetch(input, init);
		}
		// Every part starts downloading now; their bodies are passed on in order.
		const pending = [];
		for (let i = 0; i < count; i++) {
			pending.push(realFetch(`${url.pathname}.part${i}${url.search}`, init));
		}
		let index = 0;
		let reader = null;
		const body = new ReadableStream({
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
		return Promise.resolve(new Response(body, {
			status: 200,
			headers: { 'Content-Type': types[name] || 'application/octet-stream' },
		}));
	};
}());
