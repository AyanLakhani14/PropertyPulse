// server.js
const express = require("express");
const axios = require("axios");
const cheerio = require("cheerio");
const cors = require("cors");

const app = express();
app.use(cors());

app.get("/parse", async (req, res) => {
  try {
    const url = req.query.url;

    const { data } = await axios.get(url, {
      headers: {
        "User-Agent": "Mozilla/5.0",
      },
    });

    const $ = cheerio.load(data);

    const title = $("h1").first().text();
    const price = $('[data-testid="price"]').text();
    const image = $("img").first().attr("src");

    res.json({
      title: title || "Imported Property",
      price: price?.replace(/[^\d]/g, "") || "250000",
      location: title,
      size: 1500,
      condition: 3,
      image: image || "https://via.placeholder.com/150",
    });

  } catch (e) {
    res.status(500).json({ error: "Parsing failed" });
  }
});

app.listen(3000, () => console.log("Server running"));