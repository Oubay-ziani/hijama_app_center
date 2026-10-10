const express = require('express');
const authController = require('./auth.controller');
const authMiddleware = require('../../middleware/auth');

const router = express.Router();

router.post('/login', authController.login);
router.post('/register', authController.register);
router.post('/refresh', authController.refresh);
router.post('/logout', authMiddleware, authController.logout);
router.post('/change-password', authMiddleware, authController.changePassword);
router.post('/recover', authController.recoverPassword);
router.post('/reset', authController.resetPassword);

module.exports = router;
