import { Router } from "express";
import { createCoupon, getCoupons, deleteCoupon, applyCoupon } from "../controllers/coupon.controller.js";
import authUser from "../middleware/authUser.js";

const router = Router();

// Public routes (users)
router.get("/", getCoupons);
router.post("/apply", applyCoupon);

// Protected routes (owners)
// You might want to add role verification here later
router.post("/", authUser, createCoupon);
router.delete("/:id", authUser, deleteCoupon);

export default router;
