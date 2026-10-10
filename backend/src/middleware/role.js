const roleMiddleware = (allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    const roles = Array.isArray(allowedRoles) ? allowedRoles : [allowedRoles];
    
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ 
        success: false, 
        error: `Access denied. Role '${req.user.role}' does not have permission.` 
      });
    }

    next();
  };
};

module.exports = roleMiddleware;
