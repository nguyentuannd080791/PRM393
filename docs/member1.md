# Member 1 — Home Feed, Post Detail, Notifications

Covers SCR01 Home Feed, SCR02 Post Detail (with the likes bottom sheet) and SCR03 Notifications.

## REST APIs (all need `Authorization: Bearer <token>`)

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/api/feed?page=1&limit=20` | Recent posts visible to the viewer, with author, like/comment counts, `liked_by_me`, `saved_by_me` |
| GET | `/api/feed/posts/:id` | One post; 404 if deleted or not visible |
| GET | `/api/feed/posts/:id/likes` | Users who liked the post |
| PUT / DELETE | `/api/feed/posts/:id/like` | Like / unlike (idempotent); a first like notifies the author |
| PUT / DELETE | `/api/feed/posts/:id/save` | Save / unsave (idempotent) |
| GET | `/api/notifications?page=1&limit=30` | Own notifications plus `unread_count` |
| PATCH | `/api/notifications/:id/read` | Mark one read (recipient only) |
| PATCH | `/api/notifications/read-all` | Mark all own notifications read |

Visibility matches Search: public/unset audience, own posts, `friends` posts for accepted friends; `is_deleted`, `isDeleted` and `deleted_at` posts are hidden. Likes use the existing `Reaction` collection; saves use a new `SavedPost` collection (`post_id`, `user_id`, `created_at`, unique pair). `member1_indexes.js` creates the indexes at startup without deleting data.

## Flutter

`features/feed/`: `models/feed_models.dart`, `feed_repository.dart` (API), `feed_provider.dart` (feed paging, like/save lock, 15 s notification polling), `widgets/post_card.dart`, and the three screens. New route `/post/:id`; Search results now open it.

## Integration points for other members

- Member 3: override `commentsPathBuilderProvider` (`feed_provider.dart`) with the Comments route. Until then the comment button is disabled and only shows the count. Liked/Saved Posts can read the `Reaction` and `SavedPost` collections.
- Notifications of type `comment` are displayed, but creating them belongs to the Add Comment API (Member 3).

## Tests

```powershell
cd backend;  npm.cmd run test:member1
cd frontend; flutter test test/member1
```
