import mongoose from "mongoose";

const materialRequestSchema = new mongoose.Schema(
  {
    worker_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    worker_name: {
      type: String,
      required: true,
    },
    stall_name: {
      type: String,
    },
    item_name: {
      type: String,
      required: true,
    },
    quantity: {
      type: String,
      required: true,
    },
    notes: {
      type: String,
    },
    status: {
      type: String,
      enum: ["pending", "fulfilled", "rejected"],
      default: "pending",
    },
  },
  {
    timestamps: true,
  }
);

const MaterialRequest = mongoose.model("MaterialRequest", materialRequestSchema);

export default MaterialRequest;
