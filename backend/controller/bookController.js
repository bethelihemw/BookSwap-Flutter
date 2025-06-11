const Book = require("../models/books");
const qrcode = require("qrcode")

const addBook = async (req, res) => {
  try {
    const { title, author, genre, language, edition, description } = req.body;
    const owner = req.user._id;

    let photoPath = null;
    if (req.files && req.files['photo'] && req.files['photo'][0]) {
      photoPath = req.files['photo'][0].path; // Path to the uploaded photo
    }

    let pdfFilePath = null;
    if (req.files && req.files['pdf_file'] && req.files['pdf_file'][0]) {
      pdfFilePath = req.files['pdf_file'][0].path; // Path to the uploaded PDF
    }

    const newBook = new Book({
      title,
      author,
      genre,
      photo: photoPath, // Store the path to the photo
      pdf_file: pdfFilePath, // Store the path to the PDF
      language,
      edition,
      description,
      owner,
    });

    await newBook.save();

    const qrcodeData = newBook._id.toString()
    qrcode.toDataURL(qrcodeData, (err, url) =>{
      if (err) {
        console.error("Error generating QR code:", err);
        return res.status(500).json({ error: "Failed to generate QR code" })
    }
    })

     res.status(201).json({ book: newBook, qrCode: url });
  } catch (error) {
    res.json({ message: error.message });
  }
};

const getBooks = async (req, res) => {
  try {
    console.log('GET /api/books/book endpoint hit.'); // Debug log
    console.log('Request query:', req.query); // Debug log
    let {search, page, limit, genre} = req.query;
    let filter = {}
    if(search !== undefined) filter.title = new RegExp(search, "i");
    if (genre !== undefined) filter.genre = genre; // Ensure 'genre' is defined if used
    // Remove or comment out pagination for now to show all books
    // page = parseInt(page) || 1;
    // limit = parseInt(limit) || 5;
    // const skip = (page - 1) * limit;
    const books = await Book.find(filter).populate('owner', 'name');
    console.log('Books fetched:', books.length); // Debug log
    books.forEach(book => {
      console.log('getBooks: Book _id:', book._id, 'Photo path:', book.photo); // Debug log for photo path
    });
    res.status(200).json({ Books: books });
  } catch (error) {
    console.log('Error in getBooks:', error);
    res.status(404).json({ message: error.message });
  }
};

const getSingleBook = async (req, res) => {
  try {
    const book = await Book.findById(req.params.id);
    res.status(200).json({ Book: book });
  } catch (error) {
    res.status(404).json({ message: error.message });
  }
};

const update = async (req, res) => {
  console.log('DEBUG: bookController.update - PUT /api/books/book/:id endpoint hit.'); // Added debug
  console.log('DEBUG: bookController.update - Book ID:', req.params.id); // Added debug
  console.log('DEBUG: bookController.update - Request body:', req.body); // Added debug
  console.log('DEBUG: bookController.update - Authenticated user (req.user): ', req.user); // Added debug
  try {
    const book = await Book.findById(req.params.id);
    if (!book) {
      console.log('DEBUG: bookController.update - Book not found for ID:', req.params.id); // Added debug
      return res.status(404).json({ message: "Book not found" });
    }

    if (book.owner.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      console.log('DEBUG: bookController.update - Unauthorized access attempt for book ID:', req.params.id); // Added debug
      return res
        .status(403)
        .json({ message: "Unauthorized to update this book" });
    }
    const updatedBook = await Book.findOneAndUpdate(
      { _id: req.params.id },
      req.body,
      {
        new: true,
      }
    );
    console.log('DEBUG: bookController.update - Book updated successfully:', updatedBook); // Added debug
    res.status(200).json({ message: "book updated successfully", updatedBook });
  } catch (error) {
    console.error('ERROR: bookController.update - Error in update function:', error); // Added debug
    res.status(500).json({ message: error.message }); // Changed to 500 for server errors
  }
};

const deleteBook = async (req, res) => {
  console.log('DEBUG: bookController.deleteBook - DELETE /api/books/book/:id endpoint hit.'); // Added debug
  console.log('DEBUG: bookController.deleteBook - Book ID:', req.params.id); // Added debug
  console.log('DEBUG: bookController.deleteBook - Authenticated user (req.user): ', req.user); // Added debug
  try {
    const book = await Book.findById(req.params.id);
    if (!book) {
      console.log('DEBUG: bookController.deleteBook - Book not found for ID:', req.params.id); // Added debug
      return res.status(404).json({ message: "Book not found" });
    }

    if (book.owner.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      console.log('DEBUG: bookController.deleteBook - Unauthorized access attempt for book ID:', req.params.id); // Added debug
      return res
        .status(403)
        .json({ message: "Unauthorized to delete this book" });
    }

    await Book.findByIdAndDelete(req.params.id);
    console.log('DEBUG: bookController.deleteBook - Book deleted successfully for ID:', req.params.id); // Added debug
    res.status(204).send("book deleted successfully!");
  } catch (error) {
    console.error('ERROR: bookController.deleteBook - Error in deleteBook function:', error); // Added debug
    res.status(404).json({ message: error.message });
  }
};

const getMyBooks = async (req, res) => {
  try {
    const books = await Book.find({ owner: req.user._id }).populate('owner', 'name');
    books.forEach(book => console.log('getMyBooks: Book _id:', book._id)); // Debug log for _id
    res.status(200).json({ Books: books });
  } catch (error) {
    res.status(404).json({ message: error.message });
  }
};

module.exports = {
  addBook,
  deleteBook,
  update,
  getBooks,
  getSingleBook,
  getMyBooks
};
