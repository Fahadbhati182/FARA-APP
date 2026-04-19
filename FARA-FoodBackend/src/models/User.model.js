import mongoose from "mongoose";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },

    email: {
      type: String,
      required: true, 
      unique: true,
      lowercase: true,
    },

    phone: {
      type: String,
      unique: true,
      sparse: true,
    },

    password: {
      type: String,
      required: true,
      select: false, // do not return password by default
    },

    role: {
      type: String,
      enum: ["user", "worker", "admin"],
      default: "user",
    },

    stall_name: {
      type: String,
      trim: true,
    },

    addresses: [
      {
        label: { type: String }, // home, work, etc
        addressLine: { type: String, required: true },
        city: String,
        state: String,
        pincode: String,
        location: {
          lat: Number,
          lng: Number,
        },
      },
    ],

    isActive: {
      type: Boolean,
      default: true,
    },

    isVerified: {
      type: Boolean,
      default: false,
    },
    otp: {
      type: String,
      select: false,
    },
    otpExpiry: {
      type: Date,
      select: false,
    },
    resetPasswordOtp:{
      type: String,
      select: false,
    },
    resetPasswordOtpExpiry:{
      type: Date,
      select: false,
    },
    isFirstLogin: {
      type: Boolean,
      default: true,
    },
    profileImage: {
      type: String, // Cloudinary URL
    },
    defaultAddressId: {
      type: mongoose.Schema.Types.ObjectId,
    },
    favorites: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Food",
      },
    ],
  },
  {
    timestamps: true,
  },
);


userSchema.methods.comparePassword = async function (candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

userSchema.statics.hashPassword = async function (password) {
  const salt = await bcrypt.genSalt(10);
  return await bcrypt.hash(password, salt);
};

userSchema.methods.generateJWTToken = function () {
  const payload = {
    userId: this._id,
    role: this.role,
  };
  return jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN });
};

const User = mongoose.model("User", userSchema);

export default User;
