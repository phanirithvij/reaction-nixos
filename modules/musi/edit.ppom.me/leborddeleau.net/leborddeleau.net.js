const INSTANCE = "https://edit.ppom.me/leborddeleau";
const PAGES_URL = `${INSTANCE}/items/bdo_pages?fields[]=*&fields[]=images.directus_files_id&deep[images][_sort]=order`;
const NEWS_URL = `${INSTANCE}/items/bdo_actualites?fields[]=*&sort[]=date_debut&filter[date_fin][_gte]=$NOW(-1day)`;
const SETTINGS_URL = `${INSTANCE}/items/bdo_parametres`;

// TODO manage to load the image's description (maybe it's in another table or something?)
// "https://edit.ppom.me/leborddeleau/items/bdo_pages?fields[]=*&fields[]=images.directus_files_id&fields[]=images.description&deep[images][_sort]=order&filter[slug][_eq]="

async function pages() {
	const response = await fetch(PAGES_URL);
	const pages = await response.json()

	return pages.data.flatMap(page => ([
		{
			type: "text",
			path: `${page.slug}/index.md`,
			header: {
				title: page.titre,
				date: page.date_creation,
				in_search_index: true,
			},
			header_extra: {
				nb_images: page.images.length,
				description: page.description,
				contenu: page.contenu,
			},
		},
		...page.images.map(({ directus_files_id: imageid }, index) => ({
			type: "download",
			path: `${page.slug}/image-${index}.webp`,
			url: `${INSTANCE}/assets/${imageid}?key=big`,
		})),
	]));
}

async function news() {
	const response = await fetch(NEWS_URL);
	const news = await response.json()

	return [
		{
			type: "raw",
			path: "../data/news.json",
			raw: JSON.stringify(news.data),
		},
		...news.data.map(actualite => ({
			type: "download",
			path: `../static/img/${actualite.image}.webp`,
			url: `${INSTANCE}/assets/${actualite.image}?key=smallsquare`,
		})),
	];
}

async function settings() {
	const response = await fetch(SETTINGS_URL);
	const settings = await response.json()

	return [
		{
			type: "raw",
			path: "../data/settings.json",
			raw: JSON.stringify(settings.data),
		}
	];
}

function redirects() {
	return Object.entries({
		'bdo': 'projet',
		'ressources': 'espaces-de-travail',
		'activites': 'formation'
	}).map(([k, v]) => ({
		type: "text",
		path: `${k}/index.md`,
		header: {
			template: "redirect.html",
		},
		header_extra: {
			url: `./${v}/`,
		},
	}));
}

async function main() {
	console.log(JSON.stringify({
		paths: [
			...await pages(),
			...await news(),
			...await settings(),
			...redirects(),
		]
	}));
}

main();
