const express = require("express");
const routes = require("./routes");
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use("/", routes);

app.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
