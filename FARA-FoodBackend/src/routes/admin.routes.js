import express from "express";
import authUser from "../middleware/authUser.js";
import {
  addWorker,
  getAllWorkers,
  getWorkerById,
  removeWorker,
  updateWorker,
  getAdminDashboardStats,
  getAdminAllOrders,
  getAdminAllRequests,
  getAdminAnalytics,
  adminLogin,
  recordExternalOrder,
} from "../controllers/admin.controller.js";

const adminRouter = express.Router();

adminRouter.post("/login", adminLogin);

adminRouter.use(authUser);
adminRouter.post("/add-worker", addWorker);
adminRouter.put("/update-worker/:workerId", updateWorker);
adminRouter.delete("/remove-worker/:workerId", removeWorker);
adminRouter.get("/workers", getAllWorkers);
adminRouter.get("/workers/:workerId", getWorkerById);

adminRouter.get("/dashboard-stats", getAdminDashboardStats);
adminRouter.get("/all-orders", getAdminAllOrders);
adminRouter.get("/all-requests", getAdminAllRequests);
adminRouter.get("/analytics", getAdminAnalytics);
adminRouter.post("/external-order", recordExternalOrder);

export default adminRouter;
