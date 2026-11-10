# Member 4 — Search and Friend Management

Branch: `feat/member4-search-friends`.

This implementation covers SCR10 Search, SCR11 Friend Requests (Received / Sent tabs), SCR12 Friend List, and the API-backed My Posts screen. It reuses the team's authentication, JWT middleware, API client, and existing Profile screen. Other members' feed, profile, and notification screens remain outside its scope.

## Run locally (PowerShell)

Start MongoDB Community Server on the laptop, then use one terminal for the backend:

```powershell
cd C:\Users\nguye\OneDrive\Desktop\PRM393\backend
npm.cmd install
# Only when .env does not exist:
Copy-Item .env.example .env
npm.cmd start
```

Backend `.env` uses `MONGODB_URI=mongodb://127.0.0.1:27017/fb_clone`, `MONGODB_DB_NAME=fb_clone`, `PORT=5000`, and the team's `JWT_SECRET`. Keep credentials on the backend. Startup creates Member 4 indexes without deleting documents.

**Do not run `npm.cmd run db:init` against populated team data:** the existing script clears collections. Member 4 does not need that reset script.

Open `http://localhost:5000/api/health`. A second terminal runs Flutter:

```powershell
cd C:\Users\nguye\OneDrive\Desktop\PRM393\frontend
flutter pub get
flutter run -d chrome
```

Use existing registration/login to obtain a real session. Use at least two registered accounts to exercise both sides of a friendship. Screens always load real API data; the optional script below inserts separate demo fixtures only when explicitly run.

### Optional demo data

Run `npm.cmd run seed:member4` from `backend` to insert nine demo users, eight posts (six public, one private, one deleted), and six relationships with corresponding notifications. It never clears collections or resets existing request statuses, accounts, or passwords. All demo records are persisted in MongoDB; production search still uses the real API.

Login A: `member4.a@example.com` / `0904400001`. Login B: `member4.b@example.com` / `0904400002`. The shared demo password is `Demo1234!`. Account A initially has Minh Le and Tien Nguyen as friends, pending received requests from Ha Pham and Nhi Tran, and pending sent requests to Hoang Le and Quang Le. B starts without a relationship to A for testing Add Friend. Search `Minh` in People or `Flutter` in Posts. Use normal login; the existing Demo Login button is a different account.

## Android and Wi-Fi/LAN

The backend listens on `0.0.0.0`. MongoDB remains accessible only to the backend; Android devices do not connect to port 27017.

The existing `ApiClient.defaultBaseUrl` accepts `API_BASE_URL` through `--dart-define`. Defaults are `http://10.0.2.2:5000/api` for the standard Android emulator and `http://localhost:5000/api` for web/desktop.

Find the laptop's Wi-Fi IPv4 address using `ipconfig`. For physical phones on the same Wi-Fi, replace the example address:

```powershell
flutter devices
flutter run -d <android-device-id> --dart-define=API_BASE_URL=http://192.168.1.20:5000/api
```

Open `http://192.168.1.20:5000/api/health` in the phone browser first. Allow the Node.js TCP port 5000 on the laptop's private network if the firewall blocks it. Guest Wi-Fi/client isolation can prevent phone-to-laptop access. Rebuild or restart Flutter after changing a dart-define.

The existing Android manifest already has `INTERNET` permission and `android:usesCleartextTraffic="true"`, supporting HTTP on the development LAN. Keep the Node/Mongo laptop running throughout the demo.

## REST APIs

All endpoints require the existing `Authorization: Bearer <token>` header. Current-user identity comes from the verified JWT and is checked against `User`.

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/api/search/users?q=Minh&page=1&limit=20` | Partial, case-insensitive people search and relationship state |
| GET | `/api/search/posts?q=Flutter&page=1&limit=20` | Text posts, excluding deleted/media/inaccessible posts |
| GET | `/api/posts/users/:userId?page=1&limit=100` | Active posts visible to the authenticated user, with live reaction/comment counts |
| POST | `/api/posts` | Create a public post for the authenticated user; body: `{"content":"..."}` |
| PUT | `/api/posts/:id` | Edit the owner's post; body may include `content` |
| DELETE | `/api/posts/:id` | Soft-delete the owner's post |
| GET | `/api/posts/:id/insights` | Owner-only reaction, comment, and engagement counts |
| GET | `/api/friends?page=1&limit=100` | Accepted friends in both directions |
| GET | `/api/friends/status/:userId` | Relationship relative to current viewer |
| GET | `/api/friends/requests/received` | Incoming pending requests |
| GET | `/api/friends/requests/sent` | Outgoing pending requests |
| POST | `/api/friends/requests` | Send, body: `{"receiver_id":"user-id"}` |
| PATCH | `/api/friends/requests/:id/accept` | Receiver accepts |
| PATCH | `/api/friends/requests/:id/decline` | Receiver rejects |
| PATCH | `/api/friends/requests/:id/cancel` | Sender cancels |

Lists return `{success, data, pagination: {page, limit, total, has_more}}`. Mutations return `{success, data}`. Limit is 1–100, default 50. Keywords are literal strings up to 100 characters; empty searches return an empty list. Private user fields are projected out. Status codes include 400, 401, 403, 404 and 409.

## MongoDB model and consistency

The report's conceptual `users`, `posts`, `friend_requests`, `notifications` map to the repository's existing `User`, `Post`, `Friendship`, `Notification` collections and snake_case fields. Existing authentication uses UUID strings in `id` and `_id`; Member 4 preserves those identities. No parallel user collection is created.

`Friendship` stores `id`, `pair`, `requester_id`, `receiver_id`, `status`, `created_at`, `responded_at`. Statuses are `pending`, `accepted`, `rejected`, `canceled`. The unique sorted `pair` index prevents reciprocal duplicates. A pair has one record. A resend after rejection/cancel updates the record and assigns a new request ID so stale actions cannot accept a new request accidentally. Status/owner predicates in atomic updates ensure only one concurrent response succeeds. A MongoDB replica set is not required.

Accepted friendship is queried in either direction. Friend-request and friend-accept events are written to `Notification` in the existing schema with deterministic event keys. Notification insertion is idempotent; a notification failure is logged and does not roll back an already successful friendship action.

Search preserves `audience` (`public`, `friends`, `only_me`) when present, includes the viewer's own posts, and excludes `is_deleted`, `isDeleted` and non-null `deleted_at`. Plain substring regexes are escaped and time-bounded. Substring matching does not benefit fully from a normal B-tree name index; collection sizes in this local project are expected to be small. A different search index should be designed by the team for large datasets.

## Flutter integration

`features/friends/models/user_result.dart and models/friend_request.dart` defines safe API models. `repositories/search_repository.dart and repositories/friends_repository.dart` calls the REST API. `providers/search_provider.dart and providers/friends_provider.dart` coordinates search, connections and mutations. Debounce is 350 ms; a generation counter rejects outdated responses. Search loads bounded pages. Friend/request lists follow bounded API pages before local filtering. A user/request action is disabled while pending. Mutations invalidate related providers and refresh relationship statuses; visible lists also poll every 15 seconds for changes from other devices and support pull-to-refresh. Data resets when the authenticated identity changes.

The three native Flutter screens now live under features/friends/screens and follow the provided Stitch PNG/HTML/design references: fixed white canvas, white cards, blue primary actions, initials avatars and segmented controls. They use the platform sans-serif font; an Inter asset was not provided. Activity indicators and handles are not invented when the database has no such fields.

Routes:

- `/search`: SCR10.
- `/friends`: SCR12.
- `/friends/requests`: SCR11; `?tab=sent` initially opens Sent.
- On `/search`, selecting Posts with an empty query opens the signed-in user's My Posts; enter a query first to search post text.
- Legacy `/friends/search` and `/friends/all` redirect to the canonical screens.
- Existing profile, menu, notifications, authentication and post-editor paths remain available. A settings icon on the existing own-profile screen opens the existing account menu.

The four bottom destinations are Home / Search / Friends / Profile. Selecting a search post opens that author's visible active posts. Owners can create, edit, soft-delete, and inspect counts for their own posts; mutations and insights are checked against the authenticated user on the backend.

No Post Detail route exists in this checkout. Member 1 can connect their route by overriding `postDetailPathBuilderProvider` with a builder returning their route path. Search results already show full post text and let users open author profiles. No additional Post Detail screen is created here.

`.gitignore` now permits the Member 4 implementation and its tests so a fresh checkout includes the required files. It continues to exclude `.env`, node_modules, SDK caches and unrelated ignored feature modules.

## Validation commands

```powershell
cd C:\Users\nguye\OneDrive\Desktop\PRM393\backend
npm.cmd run test:member4

cd C:\Users\nguye\OneDrive\Desktop\PRM393\frontend
flutter analyze
flutter test test/member4 --reporter expanded
flutter build web
```

The backend tests use a newly generated `prm393_member4_test_*` database on the local MongoDB instance and drop only that isolated database afterward. They never call the destructive shared `db:init` script. Flutter tests use an injected fake repository, covering debounce, outdated responses, action locks, refreshed relationships, requests, friend filtering, routing and narrow layouts. Set `MEMBER4_SCREENSHOTS` to a temporary directory to save rendered test screenshots.

Multi-device Android UAT still needs the team's physical phones on the same Wi-Fi. Test run results and build evidence are reported separately after execution; this document does not claim unexecuted device scenarios passed.

## Execution evidence — 10 November 2026

- `npm.cmd run test:member4`: 12 reported Node tests passed (11 integration scenarios plus the parent workflow), using the isolated local MongoDB database.
- `flutter analyze`: No issues found.
- `flutter test test/member4 --no-pub --reporter expanded`: 9 tests passed, including error/retry, stale search responses, request actions, polling and identity reset.
- Three screen layouts and the Sent state were rendered in widget tests and inspected against Stitch references. This is not physical-device UAT.
- Web release compilation was started and stopped to shorten the work at the user's request. A successful release build is not claimed. Android APK and two-phone LAN testing were not run.
