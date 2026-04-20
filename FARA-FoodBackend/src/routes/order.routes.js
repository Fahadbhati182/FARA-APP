import { Router } from "express";
import {
  placeOrder,
  getOrderById,
  getUserOrders,
  getWorkerOrders,
  updateOrderStatus,
  resendPickupCode,
  processRefund,
} from "../controllers/order.controller.js";
import authUser from "../middleware/authUser.js";

const orderRouter = Router();

// All order routes require authentication
orderRouter.use(authUser);

orderRouter.post("/place", placeOrder);
orderRouter.get("/user/history", getUserOrders);
orderRouter.get("/worker/history", getWorkerOrders);
orderRouter.get("/:id", getOrderById);
orderRouter.patch("/status/:id", updateOrderStatus);
orderRouter.post("/resend-code/:id", resendPickupCode);
orderRouter.patch("/refund/:id", processRefund);

export default orderRouter;
