const express = require('express');
const sessionsController = require('./sessions.controller');
const authMiddleware = require('../../middleware/auth');

const router = express.Router();

router.use(authMiddleware);

router.get('/', sessionsController.getAll);
router.get('/:id', sessionsController.getById);
router.post('/', sessionsController.create);

module.exports = router;
