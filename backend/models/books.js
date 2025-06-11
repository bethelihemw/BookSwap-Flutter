const mongoose = require("mongoose");
const Schema = mongoose.Schema;
const bcrypt = require("bcrypt")

const schema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
    },
    author: {
      type: String,
      required: true,
    },
    genre: {
      type: String,
      required: true,
    },
    photo: {

      type: String,
      required: true
    },
    pdf_file: {
      type: String,
      required: false,
    },
    language: {
      type: String,
      required: false,
    },
    edition: {
      type: String,
      required: false,
    },
    description: {
      type: String,
      required: false,
    },
    owner: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true
    },
  },
  { timestamps: true }
);

const Book = mongoose.model("Book", schema);

module.exports = Book;