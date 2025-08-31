exports.home = (req, res) => res.json({ message: "Welcome to Express v3!" });
exports.health = (req, res) => res.status(200).send("OK");
exports.api = (req, res) => res.json({ version: "v3", status: "running" });
