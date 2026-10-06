// Minimal static server for the Godot web export (no dependencies).
// Usage: node tools/serve_web.js [dir=build/web] [port=8060]
const http = require("http");
const fs = require("fs");
const path = require("path");

const root = path.resolve(process.argv[2] || "build/web");
const port = Number(process.argv[3] || 8060);
const types = {
	".html": "text/html; charset=utf-8",
	".js": "text/javascript",
	".wasm": "application/wasm",
	".pck": "application/octet-stream",
	".png": "image/png",
	".svg": "image/svg+xml",
	".ico": "image/x-icon",
	".json": "application/json",
};

http.createServer((request, response) => {
	const urlPath = decodeURIComponent(request.url.split("?")[0]);
	const file = path.join(root, urlPath === "/" ? "index.html" : urlPath);
	if (!file.startsWith(root)) {
		response.writeHead(403).end();
		return;
	}
	fs.readFile(file, (error, data) => {
		if (error) {
			response.writeHead(404).end("not found");
			return;
		}
		response.writeHead(200, { "Content-Type": types[path.extname(file)] || "application/octet-stream" });
		response.end(data);
	});
}).listen(port, () => console.log(`Serving ${root} at http://localhost:${port}`));
