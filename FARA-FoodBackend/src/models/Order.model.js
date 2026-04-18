import mongoose from "mongoose";

const orderSchema = new mongoose.Schema(
  {
    customer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    customer_name: {
      type: String,
      required: true,
    },
    location: {
      type: String,
      required: true,
    },
    stall_name: {
      type: String,
      required: true,
    },
    items: [
      {
        name: { type: String, required: true },
        qty: { type: Number, required: true },
        price: { type: Number, required: true },
      },
    ],
    total: {
      type: Number,
      required: true,
    },
    order_type: {
      type: String,
      enum: ["takeaway", "delivery"],
      required: true,
    },
    status: {
      type: String,
      enum: ["pending", "accepted", "ready", "picked_up", "completed", "rejected"],
      default: "pending",
    },
    pickup_code: {
      type: String,
    },
    payment_1: {
      type: Number, // Advance payment amount
    },
    payment_2: {
      type: Number, // Balance payment amount
    },
    payment_1_at: {
      type: Date,
    },
    payment_2_at: {
      type: Date,
    },
    ready_time: {
      type: String, // e.g., "15-20 mins"
    },
    worker_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
    razorpay_payment_id: {
      type: String,
    },
    applied_coupon: {
      type: String,
    },
    discount_amount: {
      type: Number,
      default: 0,
    },
    source: {
      type: String,
      enum: ["app", "zomato", "swiggy", "offline"],
      default: "app",
    },
  },
  {
    timestamps: true,
  }
);

const Order = mongoose.model("Order", orderSchema);

export default Order;
