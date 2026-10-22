// Artifact sidecars: keep sheets first and leave headroom for the HTML and request metadata.
import { statSync, writeFileSync } from "node:fs";
import { join, resolve, isAbsolute } from "node:path";

export function writePublishFiles(dist, paths) {
	const files = [...new Set(paths)].map(path => {
		if (path.includes("\\") || isAbsolute(path) || /^[a-z]:/i.test(path) || path.split("/").includes("..")) throw new Error(`unsafe publish path: ${path}`);
		const target = resolve(dist, path);
		let bytes;
		try { const stat = statSync(target); if (!stat.isFile()) throw new Error(); bytes = stat.size; } catch { throw new Error(`publish file missing: ${path}`); }
		return { path, bytes };
	});
	const maxFiles = 250, maxBytes = 60_000_000;
	const htmlBytes = statSync(join(dist, "index.html")).size;
	const totalBytes = htmlBytes + files.reduce((sum, f) => sum + f.bytes, 0);
	const batches = [];
	let batch = [], bytes = htmlBytes;
	for (const file of files) {
		if (file.bytes + htmlBytes > maxBytes) throw new Error(`publish file exceeds batch limit: ${file.path}`);
		if (batch.length === maxFiles || bytes + file.bytes > maxBytes) { batches.push(batch); batch = []; bytes = htmlBytes; }
		batch.push({ path: file.path }); bytes += file.bytes;
	}
	if (batch.length) batches.push(batch);
	writeFileSync(join(dist, "files.json"), JSON.stringify(files.map(({ path }) => ({ path }))) + "\n");
	if (files.length > maxFiles || totalBytes > maxBytes) batches.forEach((list, i) => writeFileSync(join(dist, `files-${i + 1}.json`), JSON.stringify(list) + "\n"));
	return { sidecars: files.length, publishFiles: files.length + 1, publishBytes: totalBytes, batches: batches.length,
		versionFits: files.length + 1 <= 511 && totalBytes <= 256_000_000 };
}
