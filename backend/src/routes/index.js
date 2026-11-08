// backend/src/routes/index.js
const fs = require('fs');
const path = require('path');
const express = require('express');
const router = express.Router();

const authRoutes = require('./auth.routes');
// Mount auth routes under /api/auth
router.use('/auth', authRoutes);

// Optional modules (loaded if present)
const tryMount = (routePath, file) => {
  const filename = file.endsWith('.js') ? file : `${file}.js`;
  const filePath = path.join(__dirname, filename);
  if (fs.existsSync(filePath)) {
    router.use(routePath, require(`./${filename}`));
  }
};

tryMount('/feed', 'feed.routes');
tryMount('/', 'interaction.routes'); // handles /posts/:id/reaction, /posts/:id/comments, /comments/:id
tryMount('/posts', 'post.routes');
tryMount('/friends', 'friend.routes');
tryMount('/notifications', 'notification.routes');
tryMount('/users', 'user.routes');

module.exports = router;

