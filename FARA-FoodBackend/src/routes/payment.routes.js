import { Router } from "express";
import { 
  processPayment, 
  getPaymentLogs, 
  getAllPayments,
  createRazorpayOrder,
  verifyRazorpayPayment,
  checkRazorpayPaymentStatus
} from "../controllers/payment.controller.js";
import authUser from "../middleware/authUser.js";

const paymentRouter = Router();

paymentRouter.use(authUser);

paymentRouter.post("/process", processPayment);
paymentRouter.get("/all", getAllPayments);
paymentRouter.get("/logs/:id", getPaymentLogs);

// Razorpay specific routes
paymentRouter.post("/razorpay/create-order", createRazorpayOrder);
paymentRouter.post("/razorpay/verify", verifyRazorpayPayment);
paymentRouter.get("/razorpay/status/:orderId", checkRazorpayPaymentStatus);

export default paymentRouter;

