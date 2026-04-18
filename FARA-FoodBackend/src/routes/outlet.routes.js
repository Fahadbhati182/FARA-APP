import express from "express";
import authUser from "../middleware/authUser.js";
import {
  createOutlet,
  deleteOutlet,
  getOutletById,
  getOutlets,
  updateOutlet,
} from "../controllers/outlet.controller.js";

const outletRouter = express.Router();

outletRouter.post("/create", authUser, createOutlet);
outletRouter.get("/all", getOutlets);
outletRouter.get("/single/:id", getOutletById);
outletRouter.put("/update/:id", authUser, updateOutlet);
outletRouter.delete("/delete/:id", authUser, deleteOutlet);

export default outletRouter;
