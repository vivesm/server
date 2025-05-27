const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.json({ message: 'Todos endpoint - Coming soon', timestamp: new Date() });
});

module.exports = router;
