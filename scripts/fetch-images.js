/**
 * fetch-images.js
 * Downloads 100 random high-resolution images from picsum.photos
 * into public/gallery/ as photo-1.jpg … photo-100.jpg
 */

import { mkdirSync, existsSync, createWriteStream } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import https from "node:https";

const __dirname = dirname(fileURLToPath(import.meta.url));
const GALLERY_DIR = join(__dirname, "..", "public", "gallery");
const TOTAL_IMAGES = 100;
const IMAGE_WIDTH = 1920;
const IMAGE_HEIGHT = 1080;
const CONCURRENCY = 5; // parallel downloads to be polite to picsum

if (!existsSync(GALLERY_DIR)) {
  mkdirSync(GALLERY_DIR, { recursive: true });
}

/**
 * Download a single image, following redirects (picsum 302s to the CDN).
 * Returns a promise that resolves when the file is fully written.
 */
function downloadImage(index) {
  return new Promise((resolve, reject) => {
    const dest = join(GALLERY_DIR, `photo-${index}.jpg`);

    if (existsSync(dest)) {
      console.log(`  ✓ photo-${index}.jpg already exists, skipping`);
      return resolve();
    }

    // Add a random seed so each image is unique
    const url = `https://picsum.photos/${IMAGE_WIDTH}/${IMAGE_HEIGHT}?random=${index}`;

    const request = (location) => {
      https
        .get(location, (res) => {
          // Follow redirect
          if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
            return request(res.headers.location);
          }

          if (res.statusCode !== 200) {
            return reject(new Error(`HTTP ${res.statusCode} for photo-${index}.jpg`));
          }

          const file = createWriteStream(dest);
          res.pipe(file);
          file.on("finish", () => {
            file.close();
            console.log(`  ✓ photo-${index}.jpg downloaded`);
            resolve();
          });
          file.on("error", reject);
        })
        .on("error", reject);
    };

    request(url);
  });
}

/**
 * Run downloads in batches of CONCURRENCY to avoid hammering the server.
 */
async function main() {
  console.log(`\nDownloading ${TOTAL_IMAGES} images (${IMAGE_WIDTH}×${IMAGE_HEIGHT}) into public/gallery/\n`);

  for (let i = 0; i < TOTAL_IMAGES; i += CONCURRENCY) {
    const batch = [];
    for (let j = i; j < Math.min(i + CONCURRENCY, TOTAL_IMAGES); j++) {
      batch.push(downloadImage(j + 1));
    }
    await Promise.all(batch);
    console.log(`  — batch ${Math.floor(i / CONCURRENCY) + 1} of ${Math.ceil(TOTAL_IMAGES / CONCURRENCY)} complete\n`);
  }

  console.log("Done! All images saved to public/gallery/\n");
}

main().catch((err) => {
  console.error("Fatal error:", err);
  process.exit(1);
});
