-- =============================================================================
-- Facebook Clone (fb_clone) - PostgreSQL DDL Schema
-- Enforces: 6 Relational Tables, UUID PKs, FKs, Cascade Deletes, CHECKs, Indexes
-- =============================================================================

-- Ensure pgcrypto extension is available for UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Drop existing tables in reverse dependency order to prevent FK violations
DROP TABLE IF EXISTS "Notification" CASCADE;
DROP TABLE IF EXISTS "Friendship" CASCADE;
DROP TABLE IF EXISTS "Reaction" CASCADE;
DROP TABLE IF EXISTS "Comment" CASCADE;
DROP TABLE IF EXISTS "Post" CASCADE;
DROP TABLE IF EXISTS "User" CASCADE;

-- -----------------------------------------------------------------------------
-- 1. User Table (SDD §III.2.4)
-- -----------------------------------------------------------------------------
CREATE TABLE "User" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    birthday DATE NOT NULL,
    gender VARCHAR(10) NOT NULL,
    avatar_url TEXT,
    cover_url TEXT,
    bio TEXT,
    city VARCHAR(100),
    workplace VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_user_gender CHECK (LOWER(gender) IN ('male', 'female', 'other', 'custom')),
    CONSTRAINT chk_user_contact CHECK (email IS NOT NULL OR phone IS NOT NULL)
);

-- -----------------------------------------------------------------------------
-- 2. Post Table (SDD §III.2.4)
-- -----------------------------------------------------------------------------
CREATE TABLE "Post" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id UUID NOT NULL REFERENCES "User"(id) ON DELETE CASCADE,
    content TEXT,
    media_urls JSONB NOT NULL DEFAULT '[]'::jsonb,
    audience VARCHAR(10) NOT NULL DEFAULT 'friends',
    shared_post_id UUID REFERENCES "Post"(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_post_audience CHECK (audience IN ('public', 'friends', 'only_me'))
);

-- -----------------------------------------------------------------------------
-- 3. Comment Table (SDD §III.2.4)
-- -----------------------------------------------------------------------------
CREATE TABLE "Comment" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES "Post"(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES "User"(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 4. Reaction Table (SDD §III.2.4)
-- Composite PK (post_id, user_id) strictly enforces 1 reaction per user per post (BR-12)
-- -----------------------------------------------------------------------------
CREATE TABLE "Reaction" (
    post_id UUID NOT NULL REFERENCES "Post"(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES "User"(id) ON DELETE CASCADE,
    type VARCHAR(10) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_reaction PRIMARY KEY (post_id, user_id),
    CONSTRAINT chk_reaction_type CHECK (type IN ('like', 'love', 'haha', 'wow', 'sad', 'angry'))
);

-- -----------------------------------------------------------------------------
-- 5. Friendship Table (SDD §III.2.4)
-- -----------------------------------------------------------------------------
CREATE TABLE "Friendship" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID NOT NULL REFERENCES "User"(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES "User"(id) ON DELETE CASCADE,
    status VARCHAR(10) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    responded_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT chk_friendship_status CHECK (status IN ('pending', 'accepted')),
    CONSTRAINT chk_friendship_no_self CHECK (requester_id <> receiver_id),
    CONSTRAINT uq_friendship_direct_pair UNIQUE (requester_id, receiver_id)
);

-- Unique functional index preventing reciprocal duplicate requests (BR-15)
CREATE UNIQUE INDEX idx_friendship_bidirectional_pair ON "Friendship" (
    LEAST(requester_id, receiver_id),
    GREATEST(requester_id, receiver_id)
);

-- -----------------------------------------------------------------------------
-- 6. Notification Table (SDD §III.2.4)
-- -----------------------------------------------------------------------------
CREATE TABLE "Notification" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id UUID NOT NULL REFERENCES "User"(id) ON DELETE CASCADE,
    actor_id UUID NOT NULL REFERENCES "User"(id) ON DELETE CASCADE,
    post_id UUID REFERENCES "Post"(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_notification_type CHECK (type IN ('reaction', 'comment', 'friend_request', 'friend_accept'))
);

-- =============================================================================
-- Performance Indexes (SDD §III.2.5)
-- =============================================================================
CREATE INDEX idx_post_author_created ON "Post"(author_id, created_at DESC);
CREATE INDEX idx_comment_post_created ON "Comment"(post_id, created_at DESC);
CREATE INDEX idx_reaction_user ON "Reaction"(user_id);
CREATE INDEX idx_friendship_receiver_status ON "Friendship"(receiver_id, status);
CREATE INDEX idx_friendship_requester_status ON "Friendship"(requester_id, status);
CREATE INDEX idx_notification_recipient_unread ON "Notification"(recipient_id, is_read, created_at DESC);
CREATE INDEX idx_user_full_name ON "User"(full_name);
CREATE INDEX idx_post_shared_post ON "Post"(shared_post_id) WHERE shared_post_id IS NOT NULL;

-- -----------------------------------------------------------------------------
-- BR-10 & MSG-18: Maintain deleted shared post notification state
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_handle_shared_post_on_delete()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE "Post"
    SET media_urls = '["__original_deleted__"]'::jsonb
    WHERE shared_post_id = OLD.id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_shared_post_on_delete ON "Post";
CREATE TRIGGER trg_shared_post_on_delete
BEFORE DELETE ON "Post"
FOR EACH ROW
EXECUTE FUNCTION fn_handle_shared_post_on_delete();
