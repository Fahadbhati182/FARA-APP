import express from "express";
import authUser from "../middleware/authUser.js";
import upload from "../middleware/multer.js";
import {
  getAddresses,
  createAddress,
  updateAddress,
  deleteAddress,
  setDefaultAddress,
  updateProfile
} from "../controllers/profile.controller.js";

const profileRouter = express.Router();

profileRouter.use(authUser);

// Address routes
profileRouter.get("/addresses", getAddresses);
profileRouter.post("/addresses", createAddress);
profileRouter.put("/addresses/:id", updateAddress);
profileRouter.delete("/addresses/:id", deleteAddress);
profileRouter.patch("/addresses/default/:id", setDefaultAddress);

// Profile routes
profileRouter.post("/update", upload.single("image"), updateProfile);

export default profileRouter;
