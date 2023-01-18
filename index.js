const express = require("express");
const PORT = 8080;

const app = express();

app.use("/", (req, res) => {
  res.send("Hello!");
});

app.listen(PORT, () => console.log(`Listening on port ${PORT}`));
