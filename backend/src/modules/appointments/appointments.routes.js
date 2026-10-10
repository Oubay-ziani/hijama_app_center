const express = require('express');
const appointmentsController = require('./appointments.controller');
const authMiddleware = require('../../middleware/auth');

const router = express.Router();

router.use(authMiddleware);

router.get('/', appointmentsController.getAll);
router.get('/alerts', appointmentsController.getAlerts);
router.get('/:id', appointmentsController.getById);
router.post('/', appointmentsController.create);
router.put('/:id', appointmentsController.update);
router.delete('/:id', appointmentsController.delete);

module.exports = router;
