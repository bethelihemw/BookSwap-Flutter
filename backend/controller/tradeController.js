const Trade = require("../models/trade");
const Book = require("../models/books");
const User = require("../models/user");

const VALID_STATUSES = ["accepted", "rejected", "proposed"];

// Controller function to initiate a new trade request
const initiateTrade = async (req, res) => {
  try {
    const { requestedBookId, notes } = req.body;
    const requesterId = req.user._id;

    const requestedBook = await Book.findById(requestedBookId);

    if (!requestedBook) {
      return res.status(404).json({ message: "Requested book not found." });
    }

    if (requestedBook.owner.toString() === requesterId.toString()) {
      return res
        .status(400)
        .json({ message: "You cannot request a book you already own." });
    }

    const newTrade = new Trade({
      requester: requesterId,
      requestedBook: requestedBookId,
      owner: requestedBook.owner,
      notesFromRequester: notes,
      offeredBook: null, // Set offeredBook to null for one-way request
    });

    const savedTrade = await newTrade.save();
    res.status(201).json(savedTrade);
  } catch (error) {
    console.error("Error initiating trade:", error);
    res.status(500).json({ message: "Failed to initiate trade." });
  }
};

// Controller function to get all trade requests for the authenticated user (both as requester and owner)
const getUserTrades = async (req, res) => {
  try {
    const userId = req.user._id;
    const trades = await Trade.find({
      $or: [{ requester: userId }, { owner: userId }],
    })
      .populate("requester", "name email")
      .populate("owner", "name email")
      .populate("offeredBook", "title author photo")
      .populate("requestedBook", "title author photo")
      .populate("proposedBookFromOwner", "title author photo");
    res.status(200).json(trades);
  } catch (error) {
    console.error("Error getting user trades:", error);
    res.status(500).json({ message: "Failed to retrieve trades." });
  }
};

// Controller function to get a single trade by ID
const getSingleTrade = async (req, res) => {
  try {
    const { id } = req.params;
    const trade = await Trade.findById(id)
      .populate("requester", "name email")
      .populate("owner", "name email")
      .populate("offeredBook", "title author photo")
      .populate("requestedBook", "title author photo")
      .populate("proposedBookFromOwner", "title author photo");
    if (!trade) {
      return res.status(404).json({ message: "Trade not found." });
    }
    res.status(200).json(trade);
  } catch (error) {
    console.error("Error getting trade:", error);
    res.status(500).json({ message: "Failed to retrieve trade." });
  }
};

// Controller function for the owner of the requested book to respond to a trade request
const respondToTrade = async (req, res) => {
  try {
    const { tradeId } = req.params;
    const { status, proposedBookId, notes } = req.body;
    const ownerId = req.user._id;

    const trade = await Trade.findById(tradeId);

    if (!trade) {
      return res.status(404).json({ message: "Trade request not found." });
    }

    if (trade.owner.toString() !== ownerId.toString()) {
      return res
        .status(403)
        .json({ message: "You are not authorized to respond to this trade." });
    }

    if (!VALID_STATUSES.includes(status)) {
      return res.status(400).json({ message: "Invalid trade status." });
    }

    const updateData = { status, notesFromOwner: notes };

    if (status === "proposed" && proposedBookId) {
      const proposedBook = await Book.findById(proposedBookId);
      if (
        !proposedBook ||
        proposedBook.owner.toString() !== ownerId.toString()
      ) {
        return res.status(400).json({ message: "Invalid proposed book." });
      }
      updateData.proposedBookFromOwner = proposedBookId;
    }

    const updatedTrade = await Trade.findByIdAndUpdate(tradeId, updateData, {
      new: true,
    })
      .populate("requester", "name email")
      .populate("owner", "name email")
      .populate("offeredBook", "title author photo")
      .populate("requestedBook", "title author photo")
      .populate("proposedBookFromOwner", "title author photo");

    res.status(200).json(updatedTrade);
  } catch (error) {
    console.error("Error responding to trade:", error);
    res.status(500).json({ message: "Failed to respond to trade." });
  }
};

// Controller function for either party to cancel a trade (before acceptance/completion)
const cancelTrade = async (req, res) => {
  try {
    const { tradeId } = req.params;
    const userId = req.user._id;

    const trade = await Trade.findById(tradeId);

    if (!trade) {
      return res.status(404).json({ message: "Trade request not found." });
    }

    if (
      trade.requester.toString() !== userId.toString() &&
      trade.owner.toString() !== userId.toString()
    ) {
      return res
        .status(403)
        .json({ message: "You are not authorized to cancel this trade." });
    }

    if (["accepted", "completed"].includes(trade.status)) {
      return res
        .status(400)
        .json({
          message: "Cannot cancel a trade that has been accepted or completed.",
        });
    }

    const updatedTrade = await Trade.findByIdAndUpdate(
      tradeId,
      { status: "cancelled" },
      { new: true }
    )
      .populate("requester", "name email")
      .populate("owner", "name email")
      .populate("offeredBook", "title author photo")
      .populate("requestedBook", "title author photo")
      .populate("proposedBookFromOwner", "title author photo");

    res.status(200).json(updatedTrade);
  } catch (error) {
    console.error("Error cancelling trade:", error);
    res.status(500).json({ message: "Failed to cancel trade." });
  }
};

// Controller function to mark a trade as completed (potentially requires agreement from both parties)
const completeTrade = async (req, res) => {
  try {
    const { tradeId } = req.params;
    const userId = req.user._id; // Assuming only involved users can complete

    const trade = await Trade.findById(tradeId);

    if (!trade) {
      return res.status(404).json({ message: "Trade request not found." });
    }

    if (
      trade.requester.toString() !== userId.toString() &&
      trade.owner.toString() !== userId.toString()
    ) {
      return res
        .status(403)
        .json({ message: "You are not authorized to complete this trade." });
    }

    if (!["accepted", "proposed"].includes(trade.status)) {
      return res
        .status(400)
        .json({
          message: "Trade must be accepted or proposed before completion.",
        });
    }

    // --- Ownership transfer logic ---
    // Transfer requestedBook ownership to the requester
    const requestedBook = await Book.findById(trade.requestedBook);
    if (requestedBook) {
      requestedBook.owner = trade.requester;
      await requestedBook.save();
    }

    // If it was a two-way swap, transfer offeredBook ownership to the original owner of the requested book
    // (i.e., the 'owner' field of the trade, who is the recipient of the offered book)
    if (trade.offeredBook) {
      const offeredBook = await Book.findById(trade.offeredBook);
      if (offeredBook) {
        offeredBook.owner = trade.owner;
        await offeredBook.save();
      }
    }
    // --- End Ownership transfer logic ---

    const updatedTrade = await Trade.findByIdAndUpdate(
      tradeId,
      { status: "completed", tradeDate: new Date() },
      { new: true }
    )
      .populate("requester", "name email")
      .populate("owner", "name email")
      .populate("offeredBook", "title author photo")
      .populate("requestedBook", "title author photo")
      .populate("proposedBookFromOwner", "title author photo");

    res.status(200).json(updatedTrade);
  } catch (error) {
    console.error("Error completing trade:", error);
    res.status(500).json({ message: "Failed to complete trade." });
  }
};

// New controller function to accept a trade
const acceptTrade = async (req, res) => {
  try {
    const { id } = req.params;
    const ownerId = req.user._id;

    const trade = await Trade.findById(id);

    if (!trade) {
      return res.status(404).json({ message: "Trade request not found." });
    }

    if (trade.owner.toString() !== ownerId.toString()) {
      return res.status(403).json({
        message: "You are not authorized to accept this trade.",
      });
    }

    if (trade.status !== "pending") {
      return res
        .status(400)
        .json({ message: "Trade is not in a pending state." });
    }

    // Update trade status to accepted
    trade.status = "accepted";
    await trade.save();

    // Transfer requested book ownership to the requester (for one-way swap)
    const requestedBook = await Book.findById(trade.requestedBook);
    if (requestedBook) {
      requestedBook.owner = trade.requester; // requester becomes the new owner
      await requestedBook.save();
    }

    res.status(200).json({ message: "Trade accepted successfully!" });
  } catch (error) {
    console.error("Error accepting trade:", error);
    res.status(500).json({ message: "Failed to accept trade." });
  }
};

// New controller function to reject a trade
const rejectTrade = async (req, res) => {
  try {
    const { id } = req.params;
    const ownerId = req.user._id;

    const trade = await Trade.findById(id);

    if (!trade) {
      return res.status(404).json({ message: "Trade request not found." });
    }

    if (trade.owner.toString() !== ownerId.toString()) {
      return res.status(403).json({
        message: "You are not authorized to reject this trade.",
      });
    }

    if (trade.status !== "pending") {
      return res
        .status(400)
        .json({ message: "Trade is not in a pending state." });
    }

    // Update trade status to rejected
    trade.status = "rejected";
    await trade.save();

    res.status(200).json({ message: "Trade rejected successfully!" });
  } catch (error) {
    console.error("Error rejecting trade:", error);
    res.status(500).json({ message: "Failed to reject trade." });
  }
};

module.exports = {
  initiateTrade,
  getUserTrades,
  respondToTrade,
  cancelTrade,
  completeTrade,
  acceptTrade,
  rejectTrade,
  getSingleTrade,
};
