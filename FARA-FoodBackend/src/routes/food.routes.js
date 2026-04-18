import express from "express";
import authUser from "../middleware/authUser.js";
import {
  createFood,
  deleteFood,
  getAllFoods,
  getFoodById,
  updateFood,
} from "../controllers/food.controller.js";
import upload from "../middleware/multer.js";

const foodRouter = express.Router();

foodRouter.post("/create", authUser, upload.single("image"), createFood);
foodRouter.get("/all", getAllFoods);
foodRouter.get("/single/:id", getFoodById);
foodRouter.put("/update/:id", authUser, upload.single("image"), updateFood);
foodRouter.delete("/delete/:id", authUser, deleteFood);

export default foodRouter;
