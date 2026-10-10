const authService = require('./auth.service');

class AuthController {
  async login(req, res) {
    try {
      const { email, password } = req.body;
      if (!email || !password) {
        return res.status(400).json({ success: false, error: 'Email and password are required' });
      }

      const result = await authService.login(email, password);
      return res.status(200).json({ success: true, ...result });
    } catch (err) {
      return res.status(401).json({ success: false, error: err.message });
    }
  }

  async register(req, res) {
    try {
      const { name, email, password } = req.body;
      if (!name || !email || !password) {
        return res.status(400).json({ success: false, error: 'Name, email, and password are required' });
      }

      const result = await authService.register(name, email, password);
      return res.status(201).json({ success: true, ...result });
    } catch (err) {
      return res.status(400).json({ success: false, error: err.message });
    }
  }

  async refresh(req, res) {
    try {
      const { refreshToken } = req.body;
      if (!refreshToken) {
        return res.status(400).json({ success: false, error: 'Refresh token is required' });
      }

      const result = await authService.refreshToken(refreshToken);
      return res.status(200).json({ success: true, ...result });
    } catch (err) {
      return res.status(401).json({ success: false, error: err.message });
    }
  }

  async logout(req, res) {
    // Standard stateless logout success response
    return res.status(200).json({ success: true, message: 'Logged out successfully' });
  }

  async changePassword(req, res) {
    try {
      const { currentPassword, newPassword } = req.body;
      const userId = req.user.id;

      if (!currentPassword || !newPassword) {
        return res.status(400).json({ success: false, error: 'Current password and new password are required' });
      }

      await authService.changePassword(userId, currentPassword, newPassword);
      return res.status(200).json({ success: true, message: 'Password changed successfully' });
    } catch (err) {
      return res.status(400).json({ success: false, error: err.message });
    }
  }

  async recoverPassword(req, res) {
    try {
      const { email } = req.body;
      if (!email) {
        return res.status(400).json({ success: false, error: 'Email is required' });
      }

      const result = await authService.sendRecoveryCode(email);
      return res.status(200).json({ success: true, ...result });
    } catch (err) {
      return res.status(400).json({ success: false, error: err.message });
    }
  }

  async resetPassword(req, res) {
    try {
      const { email, code, newPassword } = req.body;
      if (!email || !code || !newPassword) {
        return res.status(400).json({ success: false, error: 'Email, code, and new password are required' });
      }

      await authService.resetPassword(email, code, newPassword);
      return res.status(200).json({ success: true, message: 'Password reset successfully' });
    } catch (err) {
      return res.status(400).json({ success: false, error: err.message });
    }
  }
}

module.exports = new AuthController();
