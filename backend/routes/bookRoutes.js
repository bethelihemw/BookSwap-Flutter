const express = require("express");
const router = express.Router();
const bookController = require("../controller/bookController")
const authMiddleware = require("../middleware/authMiddleware")
const multer = require('multer');
const path = require('path');

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/'); // Files will be stored in the 'uploads' directory
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + '-' + file.originalname); // Unique filename
  }
});

const upload = multer({ storage: storage });

router.post("/book", authMiddleware, upload.fields([{ name: 'photo', maxCount: 1 }, { name: 'pdf_file', maxCount: 1 }]), bookController.addBook)

router.get("/book", authMiddleware, bookController.getBooks)

router.get("/book/:id", authMiddleware, bookController.getSingleBook)

router.put("/book/:id", authMiddleware, bookController.update)

router.delete("/book/:id", authMiddleware, bookController.deleteBook)

router.get("/mybooks", authMiddleware, bookController.getMyBooks)

module.exports = router