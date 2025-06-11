const express = require("express");
const router = express.Router();
const tradeController = require("../controller/tradeController");
const authMiddleware = require("../middleware/authMiddleware");

router.post("/trade", authMiddleware, tradeController.initiateTrade);
router.get("/trade", authMiddleware, tradeController.getUserTrades);
router.get("/trade/:id", authMiddleware, tradeController.getSingleTrade);
router.put("/trade/:id/accept", authMiddleware, tradeController.acceptTrade);
router.put("/trade/:id/reject", authMiddleware, tradeController.rejectTrade);
router.put("/trade/:id", authMiddleware, tradeController.respondToTrade);
router.delete("/trade/:id", authMiddleware, tradeController.cancelTrade);
router.put("/trade/:id/complete", authMiddleware, tradeController.completeTrade);

module.exports = router;
