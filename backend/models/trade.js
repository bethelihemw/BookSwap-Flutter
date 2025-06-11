const mongoose = require("mongoose");
const Schema = mongoose.Schema;

const tradeSchema = new mongoose.Schema(
  {
    requester: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    offeredBook: {
      type: Schema.Types.ObjectId,
      ref: "Book",
      required: false,
    },
    requestedBook: {
      type: Schema.Types.ObjectId,
      ref: "Book",
      required: true,
    },
    owner: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    status: {
      type: String,
      enum: ["pending", "accepted", "rejected", "completed", "cancelled", "proposed"],
      default: "pending",
    },
    proposedBookFromOwner: {
      type: Schema.Types.ObjectId,
      ref: "Book",
    },
    counterAcceptedByRequester: {
      type: Boolean,
      default: false,
    },
    notesFromRequester: {
      type: String,
    },
    notesFromOwner: {
      type: String,
    },
    tradeDate: {
      type: Date,
    },
  },
  { timestamps: true }
);

const Trade = mongoose.model("Trade", tradeSchema);

module.exports = Trade;
