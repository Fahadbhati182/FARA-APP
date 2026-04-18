import mongoose from "mongoose";

const outletSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    location: {
      addressLine: { type: String, required: true },
      city: String,
      state: String,
      pincode: String,
      location: {
        lat: Number,
        lng: Number,
      },
    },
    img: String,
    isActive: {
      type: Boolean,
      default: true,
    },
    openingHours: {
      type: String,
      required: true,
    },
    workers: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
    ],
  },
  {
    timestamps: true,
  },
);

const Outlet = mongoose.model("Outlet", outletSchema);

export default Outlet;