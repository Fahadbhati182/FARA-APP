import { Router } from "express";
import {
  createMaterialRequest,
  getWorkerMaterialRequests,
  updateMaterialRequestStatus
} from "../controllers/materialRequest.controller.js";
import authUser from "../middleware/authUser.js";

const materialRequestRouter = Router();

materialRequestRouter.use(authUser);

materialRequestRouter.post("/create", createMaterialRequest);
materialRequestRouter.get("/history", getWorkerMaterialRequests);
materialRequestRouter.patch("/status/:id", updateMaterialRequestStatus);

export default materialRequestRouter;
