const POSTS_URL = "https://edit.ppom.me/pompeani.art/items/posts?fields[]=*&fields[]=technique.nom&fields[]=collection.nom&filter[status][_eq]=published&limit=-1";
const PAINTS_URL = "https://edit.ppom.me/pompeani.art/items/pages?fields[]=*&limit=-1";

async function posts() {
	const response = await fetch(POSTS_URL);
	const posts = await response.json()

	const mds = posts.data.map(post => ({
		type: "text",
		path: `${post.slug}/index.md`,
		header: {
			title: post.titre,
			date: post.date_creation,
			weight: post.ordre,
			template: 'paint.html',
			in_search_index: true,
		},
		header_extra: {
			technique: post.technique.nom,
			dimensions: `${post.hauteur_cm} x ${post.largeur_cm} cm`,
			prix: post.prix_euro ? `${post.prix_euro} €` : '',
			collection: post.collection?.nom || '',
		}
	}

	));

	const imgs = ["small", "big"].flatMap(preset => posts.data.map(post => ({
		type: "download",
		path: `${post.slug}/${preset}.webp`,
		url: `https://edit.ppom.me/pompeani.art/assets/${post.image}?download&key=${preset}`,
	})));

	return [...mds, ...imgs];
}

async function paints() {
	const response = await fetch(PAINTS_URL);
	const paints = await response.json()

	const mds = paints.data.map(page => ({
		type: "text",
		path: `${page.slug}/index.md`,
		header: {
			title: page.titre,
			date: page.date_creation,
			weight: 0,
			template: `${page.template}.html`,
			in_search_index: true,
		},
		header_extra: {
			description: page.description,
		},
		body: `
<div class="underline">
  <h1>${page.titre}</h1>
</div>

${page.texte}
`,
	}));

	const preset = "big";
	const imgs = paints.data.map(page => ({
		type: "download",
		path: `${page.slug}/${preset}.webp`,
		url: `https://edit.ppom.me/pompeani.art/assets/${page.image}?download&key=${preset}`,
	}));

	return [...mds, ...imgs];
}

async function main() {
	console.log(JSON.stringify({
		paths: [
			{
				type: "text",
				path: "_index.md",
				header: {
					sort_by: "weight"
				}
			},
			...await posts(),
			...await paints(),
		]
	}));
}

main();
