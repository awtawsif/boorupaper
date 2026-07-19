# Danbooru API Reference

REST-like API. Responses in JSON (`.json`) or XML (`.xml`).

**Test server:** `https://testbooru.donmai.us`
**Base URL:** `https://danbooru.donmai.us`

---

## Authentication

Generate API key at `https://danbooru.donmai.us/profile`.

**Query params:**
```
?login=YOUR_USERNAME&api_key=YOUR_API_KEY
```

**HTTP Basic Auth:**
```bash
curl -u "$login:$api_key" https://danbooru.donmai.us/posts.json
```

**Custom User-Agent required:**
```
User-Agent: YourBotName/1.0 (your-danbooru-username)
```

---

## Rate Limits

| Level | Read | Write |
|-------|------|-------|
| All users | 10 req/s global | — |
| Basic | — | 1 update/s |
| Gold+ | — | 4 updates/s |

Rate limits shared between accounts/IPs. Burst pool info in `x-rate-limit` header.

---

## HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | OK |
| 204 | No Content (create actions) |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 410 | Pagination limit |
| 420 | Invalid Record |
| 422 | Locked |
| 423 | Already Exists |
| 424 | Invalid Parameters |
| 429 | Throttled |
| 500 | Internal Server Error |
| 502 | Bad Gateway |
| 503 | Service Unavailable |

---

## Common Search Parameters

All index endpoints support:

| Param | Description |
|-------|-------------|
| `page` | Page number. Also supports `b<id>` (before) / `a<id>` (after) |
| `limit` | Results per page. Max: 200 (posts), 1000 (others) |
| `search[id]` | Filter by ID. Supports ranges: `100`, `>100`, `100..200` |
| `search[created_at]` | Filter by creation date. Supports ranges |
| `search[updated_at]` | Filter by update date. Supports ranges |
| `search[order]=custom` | Use `search[id]=3,2,1` for custom order |

### Parameter Parsing

- **Numeric:** `100`, `>100`, `>=100`, `<100`, `<=100`, `100,200,300`, `100..200`
- **Date:** `2012-01-01`, `>2012-01-01`, `2012-01-01..2013-01-01`
- **Boolean:** `true/t/yes/y/on/1` or `false/f/no/n/off/0`
- **String:** wildcards with `*`, escape with `\*`

---

## Posts

### Record Fields

| Field | Type | Notes |
|-------|------|-------|
| `id` | integer | |
| `rating` | string | `g`, `s`, `q`, `e` |
| `parent_id` | integer/null | |
| `source` | string | |
| `md5` | string | Only if visible |
| `uploader_id` | integer | |
| `approver_id` | integer/null | |
| `file_ext` | string | |
| `file_size` | integer | |
| `image_width` | integer | |
| `image_height` | integer | |
| `score` | integer | |
| `up_score` | integer | |
| `down_score` | integer | |
| `fav_count` | integer | |
| `is_pending` | boolean | |
| `is_flagged` | boolean | |
| `is_deleted` | boolean | |
| `tag_string` | string | Space-delimited tags |
| `tag_count` | integer | |
| `tag_count_general` | integer | |
| `tag_count_artist` | integer | |
| `tag_count_copyright` | integer | |
| `tag_count_character` | integer | |
| `tag_count_meta` | integer | |
| `has_children` | boolean | |
| `pixiv_id` | integer/null | |
| `created_at` | timestamp | |
| `updated_at` | timestamp | |

### Derived Fields

| Field | Type | Notes |
|-------|------|-------|
| `has_large` | boolean | Sample size exists |
| `has_visible_children` | boolean | |
| `file_url` | string | Original size URL (if visible) |
| `large_file_url` | string | Sample size URL (if visible) |
| `preview_file_url` | string | 180x180 thumbnail URL (if visible) |
| `tag_string_general` | string | |
| `tag_string_artist` | string | |
| `tag_string_copyright` | string | |
| `tag_string_character` | string | |
| `tag_string_meta` | string | |

### Endpoints

**Index:** `GET /posts.json`

| Param | Description |
|-------|-------------|
| `tags` | Tag query (see tag syntax below) |
| `random` | Random sampling |
| `md5` | MD5 match (takes priority) |

**Show:** `GET /posts/$id.json`

**Create:** `POST /posts.json`
- Required: `upload_media_asset_id`
- Optional: `tag_string`, `rating`, `parent_id`, `source`, `artist_commentary_title`, `artist_commentary_desc`

**Update:** `PUT /posts/$id.json`
- Optional: `tag_string`, `old_tag_string`, `parent_id`, `old_parent_id`, `source`, `old_source`, `rating`, `old_rating`, `has_embedded_notes`

**Delete:** `DELETE /posts/$id.json` (Approvers+)

**Revert:** `PUT /posts/$id/revert.json`
- Required: `version_id`

---

## Tags

### Record Fields

| Field | Type | Notes |
|-------|------|-------|
| `id` | integer | |
| `name` | string | |
| `category` | integer | 0=general, 1=artist, 3=copyright, 4=character, 5=meta |
| `post_count` | integer | |
| `is_deprecated` | boolean | |
| `created_at` | timestamp | |
| `updated_at` | timestamp | |

### Tag Categories

| Value | Description |
|-------|-------------|
| 0 | General |
| 1 | Artist |
| 3 | Copyright |
| 4 | Character |
| 5 | Meta |

### Endpoints

**Index:** `GET /tags.json`

| Param | Description |
|-------|-------------|
| `search[name]` | Tag name (string syntax) |
| `search[category]` | Category ID |
| `search[post_count]` | Post count |
| `search[name_matches]` | Normalized wildcard search |
| `search[fuzzy_name_matches]` | Fuzzy name match |
| `search[name_or_alias_matches]` | Name or alias match |
| `search[hide_empty]` | Hide zero-count tags |
| `search[is_empty]` | Only zero-count tags |
| `search[order]` | `name`, `date`, `count`, `similarity` |

**Show:** `GET /tags/$id.json`

**Update:** `PUT /tags/$id.json`
- Optional: `is_deprecated`, `category` (restricted by user level)

---

## Artists

### Record Fields

| Field | Type | Notes |
|-------|------|-------|
| `id` | integer | |
| `name` | string | Tag format |
| `group_name` | string | |
| `other_names` | array | |
| `is_banned` | boolean | |
| `is_deleted` | boolean | |
| `created_at` | timestamp | |
| `updated_at` | timestamp | |

### Endpoints

**Index:** `GET /artists.json`

| Param | Description |
|-------|-------------|
| `search[name]` | Artist name |
| `search[group_name]` | Group name |
| `search[is_deleted]` | Deleted filter |
| `search[is_banned]` | Banned filter |
| `search[any_name_matches]` | Name/group/other match (wildcards/regex) |
| `search[url_matches]` | URL match (regex or wildcard) |
| `search[any_name_or_url_matches]` | Name or URL match |
| `search[order]` | `name`, `updated_at`, `post_count` |

**Show:** `GET /artists/$id.json`

**Create:** `POST /artists.json`
- Required: `name`
- Optional: `group_name`, `other_names`, `url_string`, `is_deleted`

**Update:** `PUT /artists/$id.json` (same params as create)

**Delete:** `DELETE /artists/$id.json`

**Ban/Unban:** `PUT /artists/$id/ban.json` / `PUT /artists/$id/unban.json` (Admin only)

---

## Pools

### Record Fields

| Field | Type | Notes |
|-------|------|-------|
| `id` | integer | |
| `name` | string | |
| `description` | string | |
| `post_ids` | array | Integer IDs |
| `category` | string | `series` or `collection` |
| `is_deleted` | boolean | |
| `is_active` | boolean | |
| `created_at` | timestamp | |
| `updated_at` | timestamp | |

### Endpoints

**Index:** `GET /pools.json`

| Param | Description |
|-------|-------------|
| `search[name]` | Pool name (text syntax) |
| `search[description]` | Description (text syntax) |
| `search[post_ids]` | Post IDs (array syntax) |
| `search[category]` | `series` or `collection` |
| `search[name_contains]` | Case-insensitive search with wildcards |
| `search[post_tags_match]` | Pools whose posts match tag query |
| `search[linked_to]` | Pools linked to wiki page |
| `search[order]` | `name`, `created_at`, `post_count` |

**Show:** `GET /pools/$id.json`

**Create:** `POST /pools.json`
- Required: `name`, `category`
- Optional: `description`, `post_ids`

**Update:** `PUT /pools/$id.json`

**Delete:** `DELETE /pools/$id.json`

**Undelete:** `POST /pools/$id/undelete.json`

**Revert:** `PUT /pools/$id/revert.json`
- Required: `version_id`

---

## Post Search Tag Syntax

Used in `tags` parameter of `/posts.json`.

### Tag Types
- **General:** plain tag name `1girl`, `solo`
- **Artist:** prefixed with `artby` or just use tag name
- **Copyright:** `touhou`, `fate/grand_order`
- **Character:** `hakurei_reimu`
- **Meta:** prefixed with `status:`, `rating:`, etc.

### Rating Tags
- `rating:general` or `rating:g`
- `rating:sensitive` or `rating:s`
- `rating:questionable` or `rating:q`
- `rating:explicit` or `rating:e`

### Score
- `score:100` — exact score
- `score:>100` — score greater than
- `score:<100` — score less than

### Favorites
- `fav:USERNAME` — posts favorited by user
- `ordfav:USERNAME` — ordered by favorites from user

### Other Metatags
- `status:pending` / `status:flagged` / `status:deleted`
- `id:12345` — specific post ID
- `md5:HASH` — search by MD5
- `source:URL` — source URL
- `parent:12345` — parent post
- `child:12345` — child posts
- `has:children` / `has:parent` / `has:source` / `has:notes`
- `comment_count:10` — comment count
- `created_at:2024-01-01` — creation date
- `filesize:1mb` — file size

### Boolean Operators
- Space = AND: `1girl solo`
- `-` = NOT: `1girl -solo`
- `~` = OR: `~1girl ~1boy`

### Order Metatags
- `order:id` / `order:id_desc`
- `order:score` / `order:score_desc`
- `order:fav_count` / `order:fav_count_desc`
- `order:date` / `order:date_desc`
- `order:update` / `order:update_desc`
- `order:comment` — last comment date
- `order:mpixels` — megapixels
- `order:filesize` — file size
- `order:tagcount` — tag count
- `random` — random order

### Pagination
- `limit:20` — results per page (max 200)
- `page:2` — page number
- `page:b12345` — before post ID
- `page:a12345` — after post ID

---

## Example Requests

### Search posts by tag
```bash
curl "https://danbooru.donmai.us/posts.json?tags=1girl+solo+rating:general&limit=10"
```

### Get a specific post
```bash
curl "https://danbooru.donmai.us/posts/12345.json"
```

### Search tags
```bash
curl "https://danbooru.donmai.us/tags.json?search[name_matches]=*hakurei*"
```

### Search artists by name
```bash
curl "https://danbooru.donmai.us/artists.json?search[name_matches]=*wada*"
```

### Search pools by tag
```bash
curl "https://danbooru.donmai.us/pools.json?search[post_tags_match]=1girl"
```

### Authenticated request
```bash
curl -u "username:api_key" "https://danbooru.donmai.us/favorites.json"
```

### Random post
```bash
curl "https://danbooru.donmai.us/posts/random.json"
```

### Before/after pagination
```bash
curl "https://danbooru.donmai.us/posts.json?tags=1girl&page=b999999&limit=100"
```

---

## All API Endpoints

### Posts
| Method | Endpoint |
|--------|----------|
| GET | `/posts.json` |
| GET | `/posts/$id.json` |
| POST | `/posts.json` |
| PUT | `/posts/$id.json` |
| DELETE | `/posts/$id.json` |
| GET | `/posts/random.json` |
| PUT | `/posts/$id/revert.json` |
| GET | `/posts/$id/show_seq.json` |

### Tags
| Method | Endpoint |
|--------|----------|
| GET | `/tags.json` |
| GET | `/tags/$id.json` |
| POST | `/tags.json` |
| PUT | `/tags/$id.json` |
| DELETE | `/tags/$id.json` |

### Artists
| Method | Endpoint |
|--------|----------|
| GET | `/artists.json` |
| GET | `/artists/$id.json` |
| POST | `/artists.json` |
| PUT | `/artists/$id.json` |
| DELETE | `/artists/$id.json` |
| PUT | `/artists/$id/revert.json` |
| PUT | `/artists/$id/ban.json` |
| PUT | `/artists/$id/unban.json` |

### Pools
| Method | Endpoint |
|--------|----------|
| GET | `/pools.json` |
| GET | `/pools/$id.json` |
| POST | `/pools.json` |
| PUT | `/pools/$id.json` |
| DELETE | `/pools/$id.json` |
| POST | `/pools/$id/undelete.json` |
| PUT | `/pools/$id/revert.json` |

### Comments
| Method | Endpoint |
|--------|----------|
| GET | `/comments.json` |
| GET | `/comments/$id.json` |
| POST | `/comments.json` |
| PUT | `/comments/$id.json` |
| DELETE | `/comments/$id.json` |

### Favorites
| Method | Endpoint |
|--------|----------|
| GET | `/favorites.json` |
| POST | `/favorites.json` |
| DELETE | `/favorites/$id.json` |

### Favorite Groups
| Method | Endpoint |
|--------|----------|
| GET | `/favorite_groups.json` |
| GET | `/favorite_groups/$id.json` |
| POST | `/favorite_groups.json` |
| PUT | `/favorite_groups/$id.json` |
| DELETE | `/favorite_groups/$id.json` |

### Notes
| Method | Endpoint |
|--------|----------|
| GET | `/notes.json` |
| GET | `/notes/$id.json` |
| POST | `/notes.json` |
| PUT | `/notes/$id.json` |
| DELETE | `/notes/$id.json` |
| PUT | `/notes/$id/revert.json` |

### Wiki Pages
| Method | Endpoint |
|--------|----------|
| GET | `/wiki_pages.json` |
| GET | `/wiki_pages/$id.json` |
| POST | `/wiki_pages.json` |
| PUT | `/wiki_pages/$id.json` |
| DELETE | `/wiki_pages/$id.json` |
| PUT | `/wiki_pages/$id/revert.json` |

### Tag Aliases
| Method | Endpoint |
|--------|----------|
| GET | `/tag_aliases.json` |
| GET | `/tag_aliases/$id.json` |

### Tag Implications
| Method | Endpoint |
|--------|----------|
| GET | `/tag_implications.json` |
| GET | `/tag_implications/$id.json` |

### Post Votes
| Method | Endpoint |
|--------|----------|
| GET | `/post_votes.json` |
| POST | `/posts/$post_id/votes.json` |
| DELETE | `/posts/$post_id/votes.json` |

### Post Replacements
| Method | Endpoint |
|--------|----------|
| GET | `/post_replacements.json` |
| POST | `/post_replacements.json` |

### Post Appeals
| Method | Endpoint |
|--------|----------|
| GET | `/post_appeals.json` |
| POST | `/post_appeals.json` |

### Post Flags
| Method | Endpoint |
|--------|----------|
| GET | `/post_flags.json` |
| POST | `/post_flags.json` |

### Users
| Method | Endpoint |
|--------|----------|
| GET | `/users.json` |
| GET | `/users/$id.json` |

### Related Tags
| Method | Endpoint |
|--------|----------|
| GET | `/related_tag.json` |
| PUT | `/related_tag.json` |

### Bulk Update Requests
| Method | Endpoint |
|--------|----------|
| GET | `/bulk_update_requests.json` |
| GET | `/bulk_update_requests/$id.json` |
| POST | `/bulk_update_requests.json` |
| POST | `/bulk_update_requests/$id/approve.json` |

### IQDB Queries
| Method | Endpoint |
|--------|----------|
| GET | `/iqdb_queries.json` |
| POST | `/iqdb_queries.json` |

### Source
| Method | Endpoint |
|--------|----------|
| GET | `/source.json` |

### Status
| Method | Endpoint |
|--------|----------|
| GET | `/status.json` |

### Autocomplete
| Method | Endpoint |
|--------|----------|
| GET | `/autocomplete.json` |

### Dmails
| Method | Endpoint |
|--------|----------|
| GET | `/dmails.json` |
| POST | `/dmails.json` |
| GET | `/dmails/$id.json` |

### Forum Posts
| Method | Endpoint |
|--------|----------|
| GET | `/forum_posts.json` |
| GET | `/forum_posts/$id.json` |
| POST | `/forum_posts.json` |
| PUT | `/forum_posts/$id.json` |
| DELETE | `/forum_posts/$id.json` |

### Forum Topics
| Method | Endpoint |
|--------|----------|
| GET | `/forum_topics.json` |
| GET | `/forum_topics/$id.json` |
| POST | `/forum_topics.json` |
| PUT | `/forum_topics/$id.json` |
| DELETE | `/forum_topics/$id.json` |

### Uploads
| Method | Endpoint |
|--------|----------|
| GET | `/uploads.json` |
| GET | `/uploads/$id.json` |
| POST | `/uploads.json` |
| POST | `/uploads/preprocess.json` |

### Saved Searches
| Method | Endpoint |
|--------|----------|
| GET | `/saved_searches.json` |
| POST | `/saved_searches.json` |
| PUT | `/saved_searches/$id.json` |
| DELETE | `/saved_searches/$id.json` |

---

## Sources

- Danbooru wiki: `https://danbooru.donmai.us/wiki_pages/help:api`
- GitHub: `https://github.com/danbooru/danbooru`
