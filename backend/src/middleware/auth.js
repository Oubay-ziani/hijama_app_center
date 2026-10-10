const jwt = require('jsonwebtoken');
const env = require('../config/env');

const authMiddleware = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  if (!authHeader) {
    return res.status(401).json({ success: false, error: 'Authorization header missing' });
  }

  const token = authHeader.split(' ')[1];
  if (!token) {
    return res.status(401).json({ success: false, error: 'Token missing' });
  }

  try {
    const decoded = jwt.verify(token, env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, code: 'TOKEN_EXPIRED', error: 'JWT token expired' });
    }
    return res.status(403).json({ success: false, error: 'Invalid token' });
  }
};

module.exports = authMiddleware;
