const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../../config/db');
const env = require('../../config/env');

class AuthService {
  // Temporary cache for recovery codes (simulated memory storage)
  static recoveryCodes = new Map();

  async login(email, password) {
    const res = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    if (res.rowCount === 0) {
      throw new Error('Invalid email or password');
    }

    const user = res.rows[0];
    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      throw new Error('Invalid email or password');
    }

    const accessToken = this.generateAccessToken(user);
    const refreshToken = this.generateRefreshToken(user);

    return {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        branch_id: user.branch_id
      },
      accessToken,
      refreshToken
    };
  }

  async register(name, email, password) {
    if (!name || !email || !password) {
      throw new Error('Name, email, and password are required');
    }

    const emailCheck = await db.query('SELECT id FROM users WHERE email = $1', [email]);
    if (emailCheck.rowCount > 0) {
      throw new Error('Email is already registered');
    }

    const branchRes = await db.query('SELECT id FROM branches LIMIT 1');
    const branchId = branchRes.rowCount > 0 ? branchRes.rows[0].id : null;

    const hashedPassword = await bcrypt.hash(password, 10);
    const res = await db.query(
      `INSERT INTO users (name, email, password_hash, role, branch_id)
       VALUES ($1, $2, $3, 'EMPLOYEE', $4)
       RETURNING *`,
      [name, email, hashedPassword, branchId]
    );

    const user = res.rows[0];
    const accessToken = this.generateAccessToken(user);
    const refreshToken = this.generateRefreshToken(user);

    return {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        branch_id: user.branch_id
      },
      accessToken,
      refreshToken
    };
  }

  async refreshToken(token) {
    try {
      const decoded = jwt.verify(token, env.JWT_REFRESH_SECRET);
      
      const res = await db.query('SELECT * FROM users WHERE id = $1', [decoded.id]);
      if (res.rowCount === 0) {
        throw new Error('User not found');
      }

      const user = res.rows[0];
      const accessToken = this.generateAccessToken(user);
      const newRefreshToken = this.generateRefreshToken(user);

      return { accessToken, refreshToken: newRefreshToken };
    } catch (err) {
      throw new Error('Invalid or expired refresh token');
    }
  }

  async changePassword(userId, currentPassword, newPassword) {
    const res = await db.query('SELECT password_hash FROM users WHERE id = $1', [userId]);
    if (res.rowCount === 0) {
      throw new Error('User not found');
    }

    const { password_hash } = res.rows[0];
    const isMatch = await bcrypt.compare(currentPassword, password_hash);
    if (!isMatch) {
      throw new Error('Incorrect current password');
    }

    const newHashed = await bcrypt.hash(newPassword, 10);
    await db.query('UPDATE users SET password_hash = $1 WHERE id = $2', [newHashed, userId]);
    return true;
  }

  async sendRecoveryCode(email) {
    const res = await db.query('SELECT id, name FROM users WHERE email = $1', [email]);
    if (res.rowCount === 0) {
      throw new Error('Email not registered');
    }

    // Generate 6 digit pin
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Store in cache for 15 minutes
    AuthService.recoveryCodes.set(email, {
      code,
      expiresAt: Date.now() + 15 * 60 * 1000
    });

    // Simulated email delivery logger
    console.log(`[RECOVERY EMAIL SYSTEM] To: ${email} - Hello ${res.rows[0].name}, your 6-digit password recovery code is: ${code}`);
    
    return { email, message: 'Recovery code sent successfully (check backend server output log)' };
  }

  async resetPassword(email, code, newPassword) {
    const record = AuthService.recoveryCodes.get(email);
    if (!record) {
      throw new Error('Recovery session not found or expired');
    }

    if (record.expiresAt < Date.now()) {
      AuthService.recoveryCodes.delete(email);
      throw new Error('Recovery code expired');
    }

    if (record.code !== code) {
      throw new Error('Invalid recovery code');
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await db.query('UPDATE users SET password_hash = $1 WHERE email = $2', [hashedPassword, email]);
    
    // Clear recovery code
    AuthService.recoveryCodes.delete(email);
    return true;
  }

  generateAccessToken(user) {
    return jwt.sign(
      { id: user.id, name: user.name, role: user.role, branch_id: user.branch_id },
      env.JWT_SECRET,
      { expiresIn: env.JWT_EXPIRES_IN }
    );
  }

  generateRefreshToken(user) {
    return jwt.sign(
      { id: user.id },
      env.JWT_REFRESH_SECRET,
      { expiresIn: env.JWT_REFRESH_EXPIRES_IN }
    );
  }
}

module.exports = new AuthService();
