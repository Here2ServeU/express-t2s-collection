const express = require("express");
const { home, health, api } = require("./controllers");
const router = express.Router();

router.get("/", home);
router.get("/health", health);
router.get("/api", api);

module.exports = router;
