const User = require("../models/user");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const fs = require('fs')
require("dotenv").config();

const register = async (req, res) => {
  try {
    const { name, email, password, role } = req.body;
    const userExists = await User.findOne({ email });
    if (userExists)
      return res.status(400).json({ message: "User already exists" });
    const user = new User({
      name: name,
      email: email,
      password: password,
      profilePic: req.file ? req.file.path : undefined,
      role: role || "user",
    });
    await user.save();
    const token = jwt.sign({ id: user._id, email: user.email }, process.env.JWT_SECRET)
    res.status(200).json({ message: "user registered successfully", token });
  } catch (error) {
    res.json({ message: error.message });
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(500).json({ message: "user not found!" });

    // const isMatch = await bcrypt.compare(password, user.password);
    // if (!isMatch)
    //   return res.status(404).json({ message: "invalid credentials!" });

    if (!user || !(await user.matchPassword(password))) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    const token = jwt.sign(
      { id: user._id, email: user.email, role: user.role },
      process.env.JWT_SECRET
    );
    res.json({ token, userId: user._id, role: user.role });
  } catch (error) {
    res.send(error.message)
  }
};

// New: Check if an admin user already exists
const checkAdminStatus = async (req, res) => {
  try {
    const adminUser = await User.findOne({ role: 'admin' });
    res.status(200).json({ isAdminRegistered: !!adminUser });
  } catch (error) {
    console.error("Error checking admin status:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// New: Register the first admin user
const adminSignup = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    // Check if an admin user already exists
    const existingAdmin = await User.findOne({ role: 'admin' });
    if (existingAdmin) {
      return res.status(400).json({ message: "Admin user already registered. Only one admin allowed." });
    }

    // Check if the email is already in use by any user
    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({ message: "Email already registered." });
    }

    const adminUser = new User({
      name,
      email,
      password,
      role: 'admin', // Set role to admin
    });

    await adminUser.save();

    const token = jwt.sign(
      { id: adminUser._id, email: adminUser.email, role: adminUser.role },
      process.env.JWT_SECRET
    );

    res.status(201).json({ message: "Admin registered successfully", token, userId: adminUser._id, role: adminUser.role });
  } catch (error) {
    console.error("Error registering admin:", error);
    res.status(500).json({ message: "Failed to register admin." });
  }
};

// New: Admin login
const adminLogin = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user || user.role !== 'admin') {
      return res.status(401).json({ message: 'Invalid credentials or not an admin' });
    }

    if (!(await user.matchPassword(password))) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    const token = jwt.sign(
      { id: user._id, email: user.email, role: user.role },
      process.env.JWT_SECRET
    );
    res.json({ token, userId: user._id, role: user.role });
  } catch (error) {
    console.error("Error during admin login:", error);
    res.status(500).json({ message: "Failed to log in." });
  }
};

const getUsers = async (req, res) => {
  try {
    let { search, page, limit } = req.query;
    let filter = {}
    if (search !== undefined) filter.name = new RegExp(search, "i");
    page = parseInt(page) || 1;
    limit = parseInt(limit) || 5;
    const skip = (page - 1) * limit;
    const users = await User.find(filter).skip(skip).limit(limit);
    res.status(200).json({ users: users });
  } catch (error) {
    res.status(404).json({ message: error.message });
  }
};

const getSingleUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    res.status(200).json({ user: user });
  } catch (error) {
    res.status(404).json({ message: error.message });
  }
};

const update = async (req, res) => {
  try {
    const user = await User.findOneAndUpdate({ _id: req.params.id }, req.body, {
      new: true,
    });
    res.status(200).json({ message: "user updated successfully", user });
  } catch (error) {
    res.status(404).json({ message: error.message });
  }
};

const deleteUser = async (req, res) => {
  try {
    const user = await User.findOneAndDelete({ _id: req.params.id });
    res.status(200).json({ message: "user deleted successfully" });
  } catch (error) {
    res.status(404).json({ message: error.message });
  }
};


const updateProfilePic = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    if (user.profilePic) {
      fs.unlink(user.profilePic, (err) => {
        if (err) console.error('Failed to delete old profile pic:', err.message);
      });
    }

    user.profilePic = req.file.path;
    await user.save();

    res.json({ message: 'Profile picture updated successfully', user });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const deleteMyAccount = async (req, res) => {
  try {
    const userId = req.user._id; // Get user ID from authenticated request
    const user = await User.findByIdAndDelete(userId);

    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    res.status(200).json({ message: 'Account deleted successfully.' });
  } catch (error) {
    console.error('Error deleting account:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('-password'); // Exclude password
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.status(200).json({ user: user });
  } catch (error) {
    console.error('Error fetching user profile:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const updateMyProfile = async (req, res) => {
  try {
    const userId = req.user._id;
    const { name, email } = req.body; // Assuming only name and email can be updated for now

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    user.name = name || user.name;
    user.email = email || user.email;

    await user.save();

    res.status(200).json({ message: 'Profile updated successfully', user });
  } catch (error) {
    console.error('Error updating profile:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const changePassword = async (req, res) => {
  try {
    const userId = req.user._id;
    const { oldPassword, newPassword } = req.body;

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    // Verify old password
    const isMatch = await bcrypt.compare(oldPassword, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Old password is incorrect.' });
    }

    // Hash new password
    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(newPassword, salt);

    await user.save();

    res.status(200).json({ message: 'Password changed successfully.' });
  } catch (error) {
    console.error('Error changing password:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = { register, login, getUsers, getSingleUser, deleteUser, update, updateProfilePic, getMe, deleteMyAccount, updateMyProfile, changePassword, checkAdminStatus, adminSignup, adminLogin };
