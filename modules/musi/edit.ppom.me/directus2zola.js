import { mkdir, rm, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { pipeline } from 'node:stream/promises';
import { createWriteStream, readFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { spawn } from 'node:child_process';

import { Directus } from '@directus/sdk';

const defaultQuery = { limit: -1 };
const basedir = './zola/content';
const baseurl = 'http://127.0.0.1:8055';

async function generate() {
  // Connect
  const directus = new Directus(baseurl);

  // Create zola's content directory
  try {
    await rm(basedir, { recursive: true });
  } catch (err) {
    if (err.code !== 'ENOENT') throw err;
  }
  await mkdir(basedir, { recursive: true });
  await writeFile(join(basedir, "_index.md"), `+++
      sort_by = "weight"
    +++`
  );

  // Fetch posts
  const posts = await directus.items('posts').readByQuery({
    fields: [ 'titre', 'slug', 'status', 'ordre', 'image', 'date_creation',
      'technique.nom', 'largeur_cm', 'hauteur_cm', 'prix_euro' ],
    filter: {
      status: { "_eq": "published", },
    },
  });

  // Generate posts content
  for (const post of posts.data) {
    const md = `+++
title = "${post.titre}"
date = ${post.date_creation}
weight = ${post.ordre}
template = "paint.html"
in_search_index = true
[extra]
technique = "${post.technique.nom}"
dimensions = "${post.hauteur_cm} x ${post.largeur_cm} cm"
${post.prix_euro ? `prix = "${post.prix_euro} €"` : "prix = \"\""}
+++`;
    const dir = join(basedir, post.slug);
    await mkdir(dir);

    await writeFile(join(dir, "index.md"), md);

    for (const preset of [ "small", "big" ]) {
      const image_url = join(baseurl, `assets/${post.image}?download&key=${preset}`);
      const image = await fetch(image_url);
      await pipeline(image.body, createWriteStream(join(dir, `${preset}.webp`), image));
    }
  }

  // Fetch special pages
  const pages = await directus.items('pages').readByQuery({
    fields: [ 'titre', 'slug', 'template', 'description', 'image', 'texte', ],
  });

  // Generate pages content
  for (const page of pages.data) {
    const md = `+++
title = "${page.titre}"
date = 2022-01-01
weight = 0
template = "${page.template}.html"
in_search_index = true
[extra]
description = "${page.description}"
+++

<div class="underline">
  <h1>${page.titre}</h1>
</div>

${page.texte}
`;
    const dir = join(basedir, page.slug);
    await mkdir(dir);

    await writeFile(join(dir, "index.md"), md);

    const preset = "big";
    const image_url = join(baseurl, `assets/${page.image}?download&key=${preset}`);
    const image = await fetch(image_url);
    await pipeline(image.body, createWriteStream(join(dir, `${preset}.webp`), image));
  }
}

function execute(command, args, cwd) {
  return new Promise(function(resolve, reject) {
    const subprocess = spawn(command, args, { cwd: cwd, encoding: 'utf8' });
    let out = "";
    let err = "";
    subprocess.stdout.on('data', data => out = out.concat(data));
    subprocess.stderr.on('data', data => err = err.concat(data));
    subprocess.on('close', () => {
      if (err) {
        console.error(err);
      }
      console.log(out);
      resolve();
    });
  });
}

async function generate_build() {
  console.log('fetching data & updating git');
  let gen = generate();
  let upd = execute("git", ["pull"], "./zola/");
  await gen;
  await upd;
  console.log('building');
  await execute("zola", ["build"], "./zola/");
  console.log('uploading');
  await execute("rsync", ["-az", `--rsh=ssh -i ${process.env.D2Z_SSH_KEY}`, "./public/", process.env.D2Z_SSH_DEST], "./zola/");
  console.log('done');
}

async function requestListener(req, res) {
  res.writeHead(200);
  res.end('building');
  await generate_build();
}

generate_build()
.then(() => {
  const server = createServer(requestListener);
  server.listen(process.env.D2Z_PORT);
});
