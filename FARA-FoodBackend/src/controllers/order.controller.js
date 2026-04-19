import Order from "../models/Order.model.js";
import Outlet from "../models/Outlet.model.js";
import User from "../models/User.model.js";
import ApiError from "../utils/ApiError.js";
import ApiResponse from "../utils/ApiResponse.js";
import AsynHandler from "../utils/AsynHandler.js";
import { getIO } from "../lib/socket.js";

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
  const { status, ready_time, payment_2, payment_2_at } = req.body;

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
      // When a worker accepts a pending order, assign their ID and check outlet assignment
      if (status === "accepted" && !order.worker_id) {
        order.worker_id = userId;
      }
      order.status = status;
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
