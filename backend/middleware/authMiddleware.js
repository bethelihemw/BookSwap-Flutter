const jwt = require('jsonwebtoken')
const User = require('../models/user')
require('dotenv').config()

const authMiddleware = async(req, res, next)=>{
    try {
      const token = req.headers.authorization.split(" ")[1];
        if (!token) {
            return res.status(401).json({ message: 'Authentication failed: No token provided.' });
          }
        const decoded = jwt.verify(token, process.env.JWT_SECRET)
        const user = await User.findById(decoded.id);

    if (!user) {
      return res.status(401).json({ message: 'Authentication failed: Invalid user.' });
    }
    req.user = user;
    next();
    } catch (error) {
        console.error('Authentication error:', error);
        return res.status(401).json({ message: 'Authentication failed: Invalid token.' });
    }
}

module.exports = authMiddleware;