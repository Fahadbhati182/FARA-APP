import dotenv from "dotenv";
dotenv.config();
import express from "express";
import cors from "cors";
import connectDB from "./lib/db.js";
import connectCloudinary from "./lib/cloudinary.js";
import userRouter from "./routes/auth.routes.js";
import outletRouter from "./routes/outlet.routes.js";
import adminRouter from "./routes/admin.routes.js";
import foodRouter from "./routes/food.routes.js";
import couponRouter from "./routes/coupon.route.js";
import orderRouter from "./routes/order.routes.js";
import materialRequestRouter from "./routes/materialRequest.routes.js";
import paymentRouter from "./routes/payment.routes.js";
import profileRouter from "./routes/profile.routes.js";
import http from "http";
import { init as initSocket } from "./lib/socket.js";

await connectDB();
connectCloudinary();

const app = express();

// Middleware
app.use(express.json({ limit: "50mb" }));
app.use(express.urlencoded({ limit: "50mb", extended: true }));
app.use(
  cors({
    origin: "*",
    withCredentials: true,
  }),
);

// routes

app.use("/api/auth", userRouter);
app.use("/api/outlets", outletRouter);
app.use("/api/admin", adminRouter);
app.use("/api/foods", foodRouter);
app.use("/api/coupons", couponRouter);
app.use("/api/orders", orderRouter);
app.use("/api/requests", materialRequestRouter);
app.use("/api/payments", paymentRouter);
app.use("/api/profile", profileRouter);

app.use("/", (req, res) => {
  res.send("Welcome to the FARA Food Delivery API!");
});

const PORT = process.env.PORT || 3001;
const server = http.createServer(app);

// Initialize Socket.io
initSocket(server);

server.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

// Global Error Handler
app.use((err, req, res, next) => {
  const statusCode = err.statusCode || err.status || 500;
  const message = err.message || "Internal Server Error";
  
  if (statusCode === 500) {
    console.error(`[Error] ${statusCode} - ${message}`);
    if (err.stack) console.error(err.stack);
  }
  
  res.status(statusCode).json({
    success: false,
    statusCode,
    message,
    errors: err.errors || [],
    stack: process.env.NODE_ENV === "development" ? err.stack : undefined,
  });
});
