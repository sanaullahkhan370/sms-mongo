/*********************************
 * LOAD ENV VARIABLES (TOP)
 *********************************/
require("dotenv").config();

/*********************************
 * IMPORT PACKAGES
 *********************************/
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");

/*********************************
 * APP INITIALIZATION
 *********************************/
const app = express();
app.use(cors());
app.use(express.json());

/*********************************
 * DEBUG ENV (CONFIRM LOAD)
 *********************************/
console.log("🔍 MONGODB_URI =", process.env.MONGODB_URI);
console.log("🔍 PORT =", process.env.PORT);

/*********************************
 * MONGODB CONNECTION
 * (LATEST DRIVER – NO OPTIONS)
 *********************************/
mongoose
  .connect(process.env.MONGODB_URI)
  .then(() => {
    console.log("✅ MongoDB Connected");
  })
  .catch((err) => {
    console.error("❌ MongoDB Connection Error:", err);
  });

/*********************************
 * SCHEMA & MODEL
 *********************************/
const busSchema = new mongoose.Schema({
  busId: { type: String, required: true },
  latitude: Number,
  longitude: Number,
  updatedAt: Date,
});

const Bus = mongoose.model("Bus", busSchema, "buses");

/*********************************
 * ROUTES
 *********************************/

// 📩 SMS APP → LOCATION UPDATE
app.post("/api/location/update", async (req, res) => {
  try {
    const { busId, lat, lng } = req.body;

    console.log("📥 LOCATION RECEIVED:", req.body);

    if (!busId || !lat || !lng) {
      return res.status(400).json({
        success: false,
        message: "busId, lat, lng required",
      });
    }

    await Bus.updateOne(
      { busId },
      {
        latitude: Number(lat),
        longitude: Number(lng),
        updatedAt: new Date(),
      },
      { upsert: true }
    );

    return res.json({
      success: true,
      message: "Location updated successfully",
    });
  } catch (error) {
    console.error("❌ Update Error:", error);
    return res.status(500).json({
      success: false,
      message: "Server error",
    });
  }
});

// 🗺️ MAP APP → GET ALL BUSES
app.get("/api/buses", async (req, res) => {
  try {
    const buses = await Bus.find().sort({ updatedAt: -1 });
    return res.json(buses);
  } catch (error) {
    console.error("❌ Fetch Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch buses",
    });
  }
});

// 🧪 ROOT TEST
app.get("/", (req, res) => {
  res.send("✅ Backend is running");
});

/*********************************
 * START SERVER
 *********************************/
const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`🚀 Backend running on http://localhost:${PORT}`);
});
