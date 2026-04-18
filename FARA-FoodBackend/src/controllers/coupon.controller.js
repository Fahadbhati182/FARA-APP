import { Coupon } from "../models/Coupon.model.js";

import ApiError from "../utils/ApiError.js";
import ApiResponse from "../utils/ApiResponse.js";
import AsynHandler from "../utils/AsynHandler.js";

// @route   POST /api/v1/coupons
// @desc    Create a new coupon (Owner/Admin)
export const createCoupon = AsynHandler(async (req, res) => {
  const { title, description, code, badge, badgeColor, gradientStart, gradientEnd, expiresInDays, discountType, discountValue, minOrderValue } = req.body;

  if (!title || !description || !code || !discountValue) {
    throw new ApiError(400, "Missing required fields");
  }

  // check if coupon with code already exists
  const existingCoupon = await Coupon.findOne({ code: code.toUpperCase() });
  if (existingCoupon) {
    throw new ApiError(400, "Coupon with this code already exists");
  }

  const coupon = await Coupon.create({
    title,
    description,
    code: code.toUpperCase(),
    badge,
    badgeColor,
    gradientStart,
    gradientEnd,
    expiresInDays,
    discountType,
    discountValue,
    minOrderValue
  });

  res.status(201).json(new ApiResponse(201, "Coupon created successfully", coupon));
});

// @route   GET /api/v1/coupons
// @desc    Get all active coupons
export const getCoupons = AsynHandler(async (req, res) => {
  // Can be filtered by req.query.owner if we had multi-tenant, but keeping it simple for now
  const coupons = await Coupon.find().sort({ createdAt: -1 });

  res.status(200).json(new ApiResponse(200, "Coupons retrieved successfully", coupons));
});

// @route   DELETE /api/v1/coupons/:id
// @desc    Delete a coupon
export const deleteCoupon = AsynHandler(async (req, res) => {
  const { id } = req.params;

  const coupon = await Coupon.findByIdAndDelete(id);

  if (!coupon) {
    throw new ApiError(404, "Coupon not found");
  }

  res.status(200).json(new ApiResponse(200, "Coupon deleted successfully", coupon));
});

// @route   POST /api/v1/coupons/apply
// @desc    Apply a coupon and get discount
export const applyCoupon = AsynHandler(async (req, res) => {
  const { code, cartTotal } = req.body;

  if (!code || cartTotal == null) {
    throw new ApiError(400, "Coupon code and cartTotal are required");
  }

  const coupon = await Coupon.findOne({ code: code.toUpperCase(), isActive: true });

  if (!coupon) {
    throw new ApiError(404, "Invalid or expired coupon code");
  }

  if (cartTotal < coupon.minOrderValue) {
    throw new ApiError(400, `This coupon requires a minimum order of ₹${coupon.minOrderValue}`);
  }

  let finalPrice = cartTotal;
  let discountAmount = 0;

  if (coupon.discountType === 'PERCENTAGE') {
    discountAmount = (cartTotal * coupon.discountValue) / 100;
  } else {
    discountAmount = coupon.discountValue;
  }

  // Ensure discount doesn't exceed cart total
  if (discountAmount > cartTotal) {
    discountAmount = cartTotal;
  }

  finalPrice = cartTotal - discountAmount;

  res.status(200).json(new ApiResponse(200, "Coupon applied successfully", {
    finalPrice,
    discountAmount,
    couponCode: coupon.code,
    description: coupon.description,
  }));
});
