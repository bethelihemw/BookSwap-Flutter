const express = require("express");
const router = express.Router();
const authController = require("../controller/authController");
const authMiddleware = require("../middleware/authMiddleware");
const checkRole = require("../middleware/checkRoleMiddleware");
const upload = require("../middleware/fileUploadMiddleware");

router.post("/register", upload.single('profilePic'), authController.register);
router.post("/login", authController.login);

// Admin specific routes
router.get("/admin-status", authController.checkAdminStatus);
router.post("/admin-signup", authController.adminSignup);
router.post("/admin-login", authController.adminLogin);

router.get("/me", authMiddleware, authController.getMe);
router.put("/me", authMiddleware, authController.updateMyProfile);
router.put("/change-password", authMiddleware, authController.changePassword);

router.get("/", authMiddleware, checkRole("admin"), authController.getUsers);
router.put("/update-profile-pic/:userId", upload.single('profilePic'), authController.updateProfilePic);

router.delete("/me", authMiddleware, authController.deleteMyAccount);

router.get("/:id", authMiddleware, checkRole("admin"), authController.getSingleUser);
router.put("/:id", authMiddleware, checkRole("admin"), authController.update);
router.delete("/:id", authMiddleware, checkRole("admin"), authController.deleteUser);

module.exports = router;
