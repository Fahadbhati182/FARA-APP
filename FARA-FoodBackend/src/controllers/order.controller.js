import Order from "../models/Order.model.js";
import Outlet from "../models/Outlet.model.js";
import User from "../models/User.model.js";
import razorpay from "../lib/razorpay.js";
import ApiError from "../utils/ApiError.js";
import ApiResponse from "../utils/ApiResponse.js";
import AsynHandler from "../utils/AsynHandler.js";
import { getIO } from "../lib/socket.js";
import { sendEmail } from "../lib/nodemailer.js";

export const placeOrder = AsynHandler(async (req, res) => {
  const { userId } = req.user;
  if (!userId) {
    res.status(401);
    throw new ApiError(401, "Unauthorized");
  }

  const {
    customer_name,
    location,
    stall_name,
    items,
    total,
    order_type,
    pickup_code,
    payment_1,
    payment_2,
    payment_1_at,
    razorpay_payment_id,
  } = req.body;

  if (
    !customer_name ||
    !location ||
    !items ||
    !total ||
    !order_type ||
    !stall_name
  ) {
    res.status(400);
    throw new ApiError(400, "Missing required fields for order");
  }

  const order = await Order.create({
    customer: userId,
    customer_name,
    location,
    stall_name,
    items,
    total,
    order_type,
    pickup_code,
    payment_1,
    payment_2,
    payment_1_at,
    razorpay_payment_id,
    status: "pending",
  });

  if (!order) {
    res.status(500);
    throw new ApiError(500, "Failed to create order");
  }

  // Real-time notification for workers
  try {
    const io = getIO();
    io.to(`stall_${stall_name}`).emit("new_order", order);
  } catch (error) {
    console.error("Socket error in placeOrder:", error.message);
  }

  return res
    .status(201)
    .json(new ApiResponse(201, "Order placed successfully", order));
});

export const getOrderById = AsynHandler(async (req, res) => {
  const { id } = req.params;
  const order = await Order.findById(id);

  if (!order) {
    res.status(404);
    throw new ApiError(404, "Order not found");
  }

  return res
    .status(200)
    .json(new ApiResponse(200, "Order fetched successfully", order));
});

export const getUserOrders = AsynHandler(async (req, res) => {
  const { userId } = req.user;

  if (!userId) {
    res.status(401);
    throw new ApiError(401, "Unauthorized");
  }

  const orders = await Order.find({ customer: userId }).sort({ createdAt: -1 });

  return res
    .status(200)
    .json(new ApiResponse(200, "User orders fetched successfully", orders));
});

export const updateOrderStatus = AsynHandler(async (req, res) => {
  console.log(req.user);
  const { userId, role } = req.user;
  const { id } = req.params;
  const {
    status,
    ready_time,
    payment_2,
    payment_2_at,
    rejection_reason,
    is_manually_verified,
  } = req.body;

  if (role !== "worker" && role !== "admin") {
    res.status(403);
    throw new ApiError(
      403,
      "Forbidden: Only workers or admins can update status",
    );
  }

  const worker = await User.findById(userId);
  console.log(worker);
  if (!worker) {
    res.status(404);
    throw new ApiError(404, "Worker not found");
  }

  const assignedOutlet = await Outlet.findOne({
    workers: userId,
  });
  console.log(assignedOutlet);
  if (!assignedOutlet) {
    res.status(403);
    throw new ApiError(403, "Forbidden: You are not assigned to any outlet");
  }

  const order = await Order.findById(id);
  if (!order) {
    res.status(404);
    throw new ApiError(404, "Order not found");
  }
  console.log(order.stall_name, assignedOutlet.name);
  // Check if worker belongs to the same stall as the order
  if (role === "worker" && order.stall_name !== assignedOutlet.name) {
    res.status(403);
    throw new ApiError(
      403,
      "You can only update orders for your assigned stall",
    );
  }

    if (status) {
      if (status === "accepted" && !order.worker_id) {
        order.worker_id = userId;
      }
      
      if (status === "rejected") {
        order.rejection_reason = rejection_reason || "No reason provided";
        // refund_amount is same as payment_1 (50% advance)
        order.refund_amount = order.payment_1 || 0;
      }

      order.status = status;
    }

  if (is_manually_verified !== undefined) {
    order.is_manually_verified = is_manually_verified;
  }
  if (ready_time) order.ready_time = ready_time;
  if (payment_2 !== undefined) order.payment_2 = payment_2;
  if (payment_2_at) order.payment_2_at = payment_2_at;

  await order.save();

  // Real-time notification for customer and other workers
  try {
    const io = getIO();
    // Notify customer
    io.to(`order_${id}`).emit("order_status_update", order);
    // If it's a new acceptance, notify all workers in the stall to refresh their lists
    if (status === "accepted") {
      io.to(`stall_${order.stall_name}`).emit("order_accepted_by_other", order);
    }
  } catch (error) {
    console.error("Socket error in updateOrderStatus:", error.message);
  }

  return res
    .status(200)
    .json(new ApiResponse(200, "Order status updated successfully", order));
});

export const getWorkerOrders = AsynHandler(async (req, res) => {
  const { userId } = req.user;

  // Workers see:
  // 1. Pending takeaway orders for THEIR assigned outlets
  // 2. Orders specifically assigned to them
  const orders = await Order.find({
    $or: [
      {
        status: "pending",
        order_type: "takeaway",
      },
      { worker_id: userId },
    ],
  }).sort({ createdAt: -1 });

  return res
    .status(200)
    .json(new ApiResponse(200, "Worker orders fetched successfully", orders));
});

export const resendPickupCode = AsynHandler(async (req, res) => {
  const { id } = req.params;
  
  const order = await Order.findById(id).populate("customer", "email name");
  if (!order) {
    res.status(404);
    throw new ApiError(404, "Order not found");
  }

  if (!order.pickup_code) {
    res.status(400);
    throw new ApiError(400, "Order does not have a pickup code yet");
  }

  const customerEmail = order.customer?.email;
  if (!customerEmail) {
    res.status(400);
    throw new ApiError(400, "Customer email not found");
  }

  const subject = `Your Pickup Code - FARA Food`;
  const text = `Hello ${order.customer.name || 'Customer'},\n\nYour order #${order._id.toString().slice(-6).toUpperCase()} is ready! \n\nYour Pickup Code is: ${order.pickup_code}\n\nPlease show this code at the stall to collect your order.\n\nThank you,\nFARA Food Team`;

  await sendEmail(customerEmail, subject, text);

  return res
    .status(200)
    .json(new ApiResponse(200, "Pickup code resent successfully to customer's email"));
});

export const processRefund = AsynHandler(async (req, res) => {
  const { id } = req.params;
  const { role } = req.user;

  if (role !== "admin") {
    throw new ApiError(403, "Forbidden: Only admins can process refunds");
  }

  const order = await Order.findById(id);
  if (!order) {
    throw new ApiError(404, "Order not found");
  }

  if (order.status !== "rejected") {
    throw new ApiError(400, "Only rejected orders can be refunded");
  }

  if (order.is_refunded) {
    throw new ApiError(400, "Order is already refunded");
  }

  const refundAmount = order.refund_amount || 0;
  if (refundAmount <= 0) {
    throw new ApiError(400, "No refund amount calculated for this order");
  }

  // 1. If online order (Razorpay)
  if (order.razorpay_payment_id) {
    try {
      const refund = await razorpay.payments.refund(order.razorpay_payment_id, {
        amount: Math.round(refundAmount * 100), // convert to paise
        notes: {
          order_id: order._id.toString(),
          reason: "Order rejected by store",
        },
      });

      order.is_refunded = true;
      order.razorpay_refund_id = refund.id;
      await order.save();

      return res.status(200).json(
        new ApiResponse(200, "Refund processed successfully via Razorpay", order)
      );
    } catch (error) {
      console.error("Razorpay refund error:", error);
      throw new ApiError(500, `Razorpay Refund Failed: ${error.message}`);
    }
  } 
  
  // 2. Manual Refund (Mark as refunded)
  order.is_refunded = true;
  await order.save();

  return res.status(200).json(
    new ApiResponse(200, "Order marked as manually refunded", order)
  );
});
