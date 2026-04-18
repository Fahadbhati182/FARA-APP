import Payment from "../models/Payment.model.js";
import Order from "../models/Order.model.js";
import ApiError from "../utils/ApiError.js";
import ApiResponse from "../utils/ApiResponse.js";
import AsynHandler from "../utils/AsynHandler.js";
import crypto from "crypto";
import Razorpay from "razorpay";
import dotenv from "dotenv";

dotenv.config();

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET,
});

/**
 * @desc    Create a Razorpay Order (Advance 50%)
 * @route   POST /api/payments/razorpay/create-order
 * @access  Private (Customer)
 */
export const createRazorpayOrder = AsynHandler(async (req, res) => {
  const { amount } = req.body; // Amount in INR

  if (!amount || amount <= 0) {
    throw new ApiError(400, "Invalid payment amount");
  }

  const options = {
    amount: Math.round(amount * 100), // Razorpay expects amount in paise
    currency: "INR",
    receipt: `receipt_${Date.now()}`,
  };

  try {
    const rzpOrder = await razorpay.orders.create(options);

    // Generate a valid UPI link for your personal VPA
    const upiLink = `upi://pay?pa=8097893600@ptaxis&pn=FARA%20Food&am=${amount}&tr=${rzpOrder.id}&cu=INR`;

    return res.status(200).json(
      new ApiResponse(200, "Razorpay order created", {
        ...rzpOrder,
        upi_link: upiLink,
      }),
    );
  } catch (error) {
    console.error("Razorpay Order Creation Error:", error);
    throw new ApiError(500, error.message || "Failed to create Razorpay order");
  }
});

/**
 * @desc    Verify Razorpay Payment Signature
 * @route   POST /api/payments/razorpay/verify
 * @access  Private (Customer)
 */
export const verifyRazorpayPayment = AsynHandler(async (req, res) => {
  try {
    const {
      razorpay_order_id,
      razorpay_payment_id,
      razorpay_signature,
      verified_by_polling,
    } = req.body;

    let isAuthentic = false;

    if (verified_by_polling) {
      // If frontend says it's verified by polling, we double check with Razorpay API
      const rzpOrder = await razorpay.orders.fetch(razorpay_order_id);
      const payments = await razorpay.orders.fetchPayments(razorpay_order_id);
      isAuthentic = payments.items.some(
        (p) => p.status === "captured" || p.status === "authorized",
      );
    } else {
      // Standard signature verification
      const body = razorpay_order_id + "|" + razorpay_payment_id;
      const expectedSignature = crypto
        .createHmac("sha256", process.env.RAZORPAY_KEY_SECRET)
        .update(body.toString())
        .digest("hex");
      isAuthentic = expectedSignature === razorpay_signature;
    }

    if (!isAuthentic) {
      throw new ApiError(
        400,
        "Invalid payment signature or verification failed.",
      );
    }

    return res
      .status(200)
      .json(
        new ApiResponse(200, "Payment verified successfully", { isAuthentic }),
      );
  } catch (error) {
    console.error("Verification Error:", error);
    throw new ApiError(500, error.message || "Failed to verify Razorpay payment");
  }
});

/**
 * @desc    Check Razorpay Order Status (for polling)
 * @route   GET /api/payments/razorpay/status/:orderId
 * @access  Private (Customer)
 */
export const checkRazorpayPaymentStatus = AsynHandler(async (req, res) => {
  const { orderId } = req.params;

  try {
    const rzpOrder = await razorpay.orders.fetch(orderId);
    const payments = await razorpay.orders.fetchPayments(orderId);

    // Check if any payment for this order is captured or authorized
    const isPaid = payments.items.some(
      (p) => p.status === "captured" || p.status === "authorized",
    );

    return res.status(200).json(
      new ApiResponse(200, "Order status fetched", {
        status: rzpOrder.status,
        isPaid: isPaid,
        payments: payments.items,
      }),
    );
  } catch (error) {
    throw new ApiError(
      500,
      error.message || "Failed to fetch Razorpay order status",
    );
  }
});

export const processPayment = AsynHandler(async (req, res) => {
  const { userId, role } = req.user;
  const { orderId, amount, method } = req.body;

  if (role !== "worker" && role !== "admin") {
    res.status(403);
    throw new ApiError(
      403,
      "Only workers or admins can process final payments",
    );
  }

  const order = await Order.findById(orderId);
  if (!order) {
    res.status(404);
    throw new ApiError(404, "Order not found");
  }

  // 1. Initialize Payment Record
  const transactionId = `TXN_${crypto.randomBytes(8).toString("hex").toUpperCase()}`;
  const payment = await Payment.create({
    order: orderId,
    customer: order.customer,
    worker: userId,
    amount,
    method,
    transactionId,
    logs: [
      {
        message: `Final settlement initiated via ${method}. Amount: ₹${amount}`,
        type: "info",
      },
    ],
  });

  try {
    if (method === "cash") {
      payment.status = "success";
      payment.logs.push({
        message: "Cash payment confirmed by worker.",
        type: "info",
      });
    } else if (method === "online") {
      // For final settlement, if online, assume it's already verified via frontend SDK
      payment.status = "success";
      payment.logs.push({
        message: "Online final payment confirmed.",
        type: "info",
      });
    }

    if (payment.status === "success") {
      order.status = "completed";
      order.payment_2 = amount;
      order.payment_2_at = new Date();
      await order.save();

      payment.logs.push({
        message: "Order marked as completed.",
        type: "info",
      });
    }

    await payment.save();
    return res
      .status(200)
      .json(new ApiResponse(200, "Payment processed successfully", payment));
  } catch (error) {
    payment.status = "failed";
    payment.logs.push({
      message: `Internal Error: ${error.message}`,
      type: "error",
    });
    await payment.save();
    throw new ApiError(
      500,
      error.message || "An error occurred during payment processing",
    );
  }
});

export const getPaymentLogs = AsynHandler(async (req, res) => {
  const { id } = req.params;
  const payment = await Payment.findById(id).populate("order customer worker");

  if (!payment) {
    res.status(404);
    throw new ApiError(404, "Payment record not found");
  }

  return res
    .status(200)
    .json(new ApiResponse(200, "Payment logs fetched", payment));
});

export const getAllPayments = AsynHandler(async (req, res) => {
  const { role } = req.user;

  if (role !== "admin") {
    res.status(403);
    throw new ApiError(403, "Only admins can access all payment records");
  }

  const payments = await Payment.find()
    .populate("order", "customer_name total status createdAt")
    .populate("customer", "name email phone")
    .populate("worker", "name")
    .sort({ createdAt: -1 });

  return res
    .status(200)
    .json(new ApiResponse(200, "All payments fetched successfully", payments));
});
