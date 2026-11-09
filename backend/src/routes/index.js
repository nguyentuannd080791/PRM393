// backend/src/routes/index.js
const fs = require('fs');
const path = require('path');
const express = require('express');
const router = express.Router();

const authRoutes = require('./auth.routes');
// Mount auth routes under /api/auth
router.use('/auth', authRoutes);
router.use('/search', require('./search.routes'));

// Optional modules (loaded if present)
const tryMount = (routePath, file) => {
  const filename = file.endsWith('.js') ? file : `${file}.js`;
  const filePath = path.join(__dirname, filename);
  if (fs.existsSync(filePath)) {
    router.use(routePath, require(`./${filename}`));
  }
};

tryMount('/feed', 'feed.routes');
tryMount('/', 'interactions.routes'); // handles /posts/:id/reaction, /posts/:id/comments, /comments/:id
tryMount('/posts', 'posts.routes');
tryMount('/friends', 'friends.routes');
tryMount('/notifications', 'notification.routes');
tryMount('/users', 'user.routes');

tryMount('/profile', 'profile.routes');

module.exports = router;
