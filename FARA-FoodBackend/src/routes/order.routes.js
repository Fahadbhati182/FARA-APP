import { Router } from "express";
import {
  placeOrder,
  getOrderById,
  getUserOrders,
  getWorkerOrders,
  updateOrderStatus,
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

export default orderRouter;
