import mongoose, { Schema } from 'mongoose';

const couponSchema = new Schema(
  {
    title: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      required: true,
      trim: true,
    },
    code: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      uppercase: true,
    },
    badge: {
      type: String,
      default: "DEAL",
      trim: true,
    },
    badgeColor: {
      type: String, // hex code like "#FF5733" or "0xFF5733"
      default: "0xFFFF6B2C", // Matches primaryOrange by default
    },
    gradientStart: {
      type: String,
      default: "0xFFFF6B2C",
    },
    gradientEnd: {
      type: String,
      default: "0xFFFF9A5C",
    },
    expiresInDays: {
      type: Number,
      default: 7, 
    },
    discountType: {
      type: String,
      enum: ['PERCENTAGE', 'FLAT_AMOUNT'],
      default: 'PERCENTAGE',
    },
    discountValue: {
      type: Number,
      required: true,
    },
    minOrderValue: {
      type: Number,
      default: 0,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

export const Coupon = mongoose.model('Coupon', couponSchema);
