# Wallhaven API (v1) Documentation

The current version (v1) of the API supports basic `GET` requests via URL. Users can grant API access to certain account settings using an API key found in their account settings. This key can be regenerated at any time.

---

## Authentication

Authenticate by either:

- Appending `?apikey=<API_KEY>` to the request URL, **or**
- Including the header `X-API-Key: <API_KEY>` with the request

---

## Accessing Wallpaper Information

```
GET https://wallhaven.cc/api/v1/w/<ID>
```

> NSFW wallpapers are blocked for guests. Provide your API key to access them:
> `https://wallhaven.cc/api/v1/w/<ID>?apikey=<API_KEY>`

### Example Request

```
GET https://wallhaven.cc/api/v1/w/94x38z
```

### Example Response

```json
{
  "data": {
    "id": "94x38z",
    "url": "https://wallhaven.cc/w/94x38z",
    "short_url": "http://whvn.cc/94x38z",
    "uploader": {
      "username": "test-user",
      "group": "User",
      "avatar": {
        "200px": "https://wallhaven.cc/images/user/avatar/200/11_3339efb2a813.png",
        "128px": "https://wallhaven.cc/images/user/avatar/128/11_3339efb2a813.png",
        "32px": "https://wallhaven.cc/images/user/avatar/32/11_3339efb2a813.png",
        "20px": "https://wallhaven.cc/images/user/avatar/20/11_3339efb2a813.png"
      }
    },
    "views": 12,
    "favorites": 0,
    "source": "",
    "purity": "sfw",
    "category": "anime",
    "dimension_x": 6742,
    "dimension_y": 3534,
    "resolution": "6742x3534",
    "ratio": "1.91",
    "file_size": 5070446,
    "file_type": "image/jpeg",
    "created_at": "2018-10-31 01:23:10",
    "colors": ["#000000", "#abbcda", "#424153", "#66cccc", "#333399"],
    "path": "https://w.wallhaven.cc/full/94/wallhaven-94x38z.jpg",
    "thumbs": {
      "large": "https://th.wallhaven.cc/lg/94/94x38z.jpg",
      "original": "https://th.wallhaven.cc/orig/94/94x38z.jpg",
      "small": "https://th.wallhaven.cc/small/94/94x38z.jpg"
    },
    "tags": [
      {
        "id": 1,
        "name": "anime",
        "alias": "Chinese cartoons",
        "category_id": 1,
        "category": "Anime & Manga",
        "purity": "sfw",
        "created_at": "2015-01-16 02:06:45"
      }
    ]
  }
}
```

---

## Searching and Listings

Search behaves the same as the site's native search. All standard search URL parameters are supported.

```
GET https://wallhaven.cc/api/v1/search
```

With an API key, searches respect the user's browsing settings and default filters:

```
GET https://wallhaven.cc/api/v1/search?apikey=<API_KEY>
```

With no additional parameters, the search returns the latest SFW wallpapers.

> Listings are limited to **24 results per page**. Meta information is included with each response for pagination.

### Search Parameters

| Parameter | Allowed Values / Examples | Description |
|---|---|---|
| `q` | `tagname` – fuzzy tag/keyword search · `-tagname` – exclude a tag/keyword · `+tag1 +tag2` – must have both tags · `+tag1 -tag2` – must have tag1, not tag2 · `@username` – user uploads · `id:123` – exact tag search (cannot be combined) · `type:{png/jpg}` – search by file type (`jpg` = jpeg) · `like:wallpaperID` – find wallpapers with similar tags | Main search query |
| `categories` | `100` / `101` / `111`* / etc. (general/anime/people) | Turn categories on (`1`) or off (`0`) |
| `purity` | `100`* / `110` / `111` / etc. (sfw/sketchy/nsfw) | Turn purities on (`1`) or off (`0`). NSFW requires a valid API key |
| `sorting` | `date_added`*, `relevance`, `random`, `views`, `favorites`, `toplist` | Method of sorting results |
| `order` | `desc`*, `asc` | Sorting order |
| `topRange` | `1d`, `3d`, `1w`, `1M`*, `3M`, `6M`, `1y` | Sorting range — requires `sorting=toplist` |
| `atleast` | `1920x1080` | Minimum resolution allowed |
| `resolutions` | `1920x1080,1920x1200` | List of exact wallpaper resolutions (single resolution allowed) |
| `ratios` | `16x9,16x10` | List of aspect ratios (single ratio allowed) |
| `colors` | `660000`, `990000`, `cc0000`, `cc3333`, `ea4c88`, `993399`, `663399`, `333399`, `0066cc`, `0099cc`, `66cccc`, `77cc33`, `669900`, `336600`, `666600`, `999900`, `cccc33`, `ffff00`, `ffcc33`, `ff9900`, `ff6600`, `cc6633`, `996633`, `663300`, `000000`, `999999`, `cccccc`, `ffffff`, `424153` | Search by color |
| `page` | `1`, `2`, ... | Pagination (not truly infinite) |
| `seed` | `[a-zA-Z0-9]{6}` | Optional seed for random results |

*\* = default*

**Notes:**
- Sorting by `random` returns a seed you can pass between pages to avoid repeats.
- When searching by exact tag (`id:##`), if the tag exists, the resolved tag name is included in the response metadata.

### Example Response

```json
{
  "data": [
    {
      "id": "94x38z",
      "url": "https://wallhaven.cc/w/94x38z",
      "short_url": "http://whvn.cc/94x38z",
      "views": 6,
      "favorites": 0,
      "source": "",
      "purity": "sfw",
      "category": "anime",
      "dimension_x": 6742,
      "dimension_y": 3534,
      "resolution": "6742x3534",
      "ratio": "1.91",
      "file_size": 5070446,
      "file_type": "image/jpeg",
      "created_at": "2018-10-31 01:23:10",
      "colors": ["#000000", "#abbcda", "#424153", "#66cccc", "#333399"],
      "path": "https://w.wallhaven.cc/94/wallhaven-94x38z.jpg",
      "thumbs": {
        "large": "https://th.wallhaven.cc/lg/94/94x38z.jpg",
        "original": "https://th.wallhaven.cc/orig/94/94x38z.jpg",
        "small": "https://th.wallhaven.cc/small/94/94x38z.jpg"
      }
    },
    {
      "id": "ze1p56",
      "url": "https://wallhaven.cc/w/ze1p56",
      "short_url": "http://whvn.cc/ze1p56",
      "views": 11,
      "favorites": 0,
      "source": "",
      "purity": "sfw",
      "category": "anime",
      "dimension_x": 3779,
      "dimension_y": 2480,
      "resolution": "3779x2480",
      "ratio": "1.52",
      "file_size": 1011043,
      "file_type": "image/jpeg",
      "created_at": "2018-10-07 17:05:28",
      "colors": ["#424153", "#e7d8b1", "#cc3333", "#ffffff", "#cccccc"],
      "path": "https://w.wallhaven.cc/ze/wallhaven-ze1p56.jpg",
      "thumbs": {
        "large": "https://th.wallhaven.cc/lg/ze/ze1p56.jpg",
        "original": "https://th.wallhaven.cc/orig/ze/ze1p56.jpg",
        "small": "https://th.wallhaven.cc/small/ze/ze1p56.jpg"
      }
    }

    // ...additional results omitted for brevity
  ],
  "meta": {
    "current_page": 1,
    "last_page": 36,
    "per_page": 24,
    "total": 848,

    // "query" is a string for normal searches, or an object for exact tag searches:
    "query": "test",
    // "query": { "id": 1, "tag": "anime" },

    "seed": "abc123" // or null
  }
}
```

---

## Tag Info

```
GET https://wallhaven.cc/api/v1/tag/<ID>
```

### Example Response

```json
{
  "data": {
    "id": 1,
    "name": "anime",
    "alias": "Chinese cartoons",
    "category_id": 1,
    "category": "Anime & Manga",
    "purity": "sfw",
    "created_at": "2015-01-16 02:06:45"
  }
}
```

---

## User Settings

Authenticated users can read their settings via:

```
GET https://wallhaven.cc/api/v1/settings?apikey=<API_KEY>
```

### Example Response

```json
{
  "data": {
    "thumb_size": "orig",
    "per_page": "24",
    "purity": ["sfw", "sketchy", "nsfw"],
    "categories": ["general", "anime", "people"],
    "resolutions": ["1920x1080", "2560x1440"],
    "aspect_ratios": ["16x9"],
    "toplist_range": "6M",
    "tag_blacklist": ["blacklist tag", "another"],
    "user_blacklist": [""]
  }
}
```

---

## User Collections

**List your own collections** (requires API key):
```
GET https://wallhaven.cc/api/v1/collections?apikey=<API_KEY>
```

**List another user's public collections:**
```
GET https://wallhaven.cc/api/v1/collections/<USERNAME>
```

> Only public collections are visible to other users. Authenticated users can view all of their own collections, including private ones.

**View wallpapers within a specific collection:**
```
GET https://wallhaven.cc/api/v1/collections/<USERNAME>/<ID>
```
Returns a listing similar to search results, but only the `purity` filter is available. Authenticated users can access their own private collections with their API key.

### Example Response

```json
{
  "data": [
    {
      "id": 15,
      "label": "Default",
      "views": 38,
      "public": 1,
      "count": 10
    },
    {
      "id": 17,
      "label": "This is another collection",
      "views": 6,
      "public": 1,
      "count": 7
    }
  ]
}
```

---

## Rate Limiting & Errors

| Scenario | Result |
|---|---|
| More than **45 API calls per minute** | `429 – Too many requests` |
| Accessing NSFW content without an API key (or an invalid one) | `401 – Unauthorized` |
| Any other invalid API key usage | `401 – Unauthorized` |

---

## Changes to the API

Wallhaven aims to communicate API changes in advance, but reserves the right to make unannounced changes when necessary. Plan your integrations accordingly.

> This API is provided for free and as-is, with no warranty.

---

*All images remain the property of their original owners.*
© wallhaven.cc 2026 · [Privacy Policy] · [Terms of Service]
