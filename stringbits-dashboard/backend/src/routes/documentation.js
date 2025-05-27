const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.json({ message: 'Documentation endpoint - Coming soon', timestamp: new Date() });
});

module.exports = router;
