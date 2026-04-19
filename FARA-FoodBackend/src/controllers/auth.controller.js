import { sendEmail } from "../lib/nodemailer.js";
import User from "../models/User.model.js";
import ApiError from "../utils/ApiError.js";
import ApiResponse from "../utils/ApiResponse.js";
import AsynHandler from "../utils/AsynHandler.js";
import Outlet from "../models/Outlet.model.js";

export const registerUser = AsynHandler(async (req, res) => {
  const { name, email, password, role } = req.body;

  if (!name || !email || !password) {
    res.status(400);
    throw new ApiError(400, "Please fill all the fields");
  }

  const exitingUser = await User.findOne({ email });

  if (exitingUser) {
    res.status(400);
    throw new ApiError(400, "User already exists");
  }

  const hashPassword = await User.hashPassword(password);

  // map frontend roles to backend roles
  let backendRole = "user";
  if (role === "admin" || role === "owner") backendRole = "admin";
  else if (role === "worker") backendRole = "worker";

  const user = await User.create({
    name,
    email,
    password: hashPassword,
    role: backendRole,
  });

  if (!user) {
    res.status(500);
    throw new ApiError(500, "Something went wrong");
  }

  res
    .status(201)
    .json(new ApiResponse(201, "User registered successfully", user));
});

export const loginUser = AsynHandler(async (req, res) => {
  const { email, password, role } = req.body;

  console.log(email, password, role, "In register user");

  if (!email || !password) {
    res.status(400);
    throw new ApiError(400, "Please fill all the fields");
  }

  const cleanEmail = email.trim().toLowerCase();
  const user = await User.findOne({ email: cleanEmail }).select("+password");
  console.log("User found:", user ? user.email : "null");

  if (!user) {
    res.status(400);
    throw new ApiError(400, "Invalid credentials");
  }

  const isMatch = await user.comparePassword(password);
  if (!isMatch) {
    res.status(400);
    throw new ApiError(400, "Invalid credentials");
  }

  if (role !== user.role) {
    res.status(400);
    throw new ApiError(400, "Invalid role");
  }

  const token = user.generateJWTToken();

  res.cookie("token", token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "strict",
    maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
  });

  res
    .status(200)
    .json(new ApiResponse(200, "Logged in successfully", { token, user }));
});

export const logoutUser = AsynHandler(async (req, res) => {
  res.clearCookie("token");
  res.status(200).json(new ApiResponse(200, "Logged out successfully", null));
});

export const getCurrentUser = AsynHandler(async (req, res) => {
  const { userId: loginUserId } = req.user;
  const user = await User.findById(loginUserId);

  if (!user) {
    res.status(404);
    throw new ApiError(404, "User not found");
  }

  // Dynamically populate stall_name for workers if it's missing
  if (user.role === "worker" && !user.stall_name) {
    const assignedOutlet = await Outlet.findOne({ workers: loginUserId });
    if (assignedOutlet) {
      user.stall_name = assignedOutlet.name;
      // We don't necessarily need to save it here, just return it in the response
    }
  }

  res.status(200).json(new ApiResponse(200, "User fetched successfully", user));
});

export const isAuthenticated = AsynHandler(async (req, res) => {
  const { userId: loginUserId } = req.user;
  if (!loginUserId) {
    res.status(401);
    throw new ApiError(401, "Unauthorized");
  }

  res.status(200).json(new ApiResponse(200, "User is authenticated", null));
});

export const sendVerifyEmailOTP = AsynHandler(async (req, res) => {
  const { userId: loginUserId } = req.user;

  if (!loginUserId) {
    res.status(401);
    throw new ApiError(401, "Unauthorized");
  }

  const user = await User.findById(loginUserId);

  if (!user) {
    res.status(404);
    throw new ApiError(404, "User not found");
  }

  if (user.isVerified) {
    res.status(400);
    throw new ApiError(400, "Email is already verified");
  }

  const OTP = Math.floor(100000 + Math.random() * 900000);
  user.otp = OTP;
  user.otpExpiry = Date.now() + 5 * 60 * 1000; // 5 minutes

  await user.save();

  sendEmail(
    user.email,
    "Verify your email",
    `
    Your OTP for email verification is: ${OTP}
    
    This OTP is valid for 5 minutes.
      `,
  );

  res.status(200).json(new ApiResponse(200, "OTP sent successfully", null));
});

export const verifyEmailOTP = AsynHandler(async (req, res) => {
  const { userId: loginUserId } = req.user;
  const { otp } = req.body;

  if (!loginUserId) {
    res.status(401);
    throw new ApiError(401, "Unauthorized");
  }

  const user = await User.findById(loginUserId).select("+otp +otpExpiry");

  if (!user) {
    res.status(404);
    throw new ApiError(404, "User not found");
  }

  if (user.isVerified) {
    res.status(400);
    throw new ApiError(400, "Email is already verified");
  }

  if (user.otp !== otp || user.otpExpiry < Date.now()) {
    res.status(400);
    throw new ApiError(400, "Invalid or expired OTP");
  }

  user.isVerified = true;
  user.otp = undefined;
  user.otpExpiry = undefined;
  await user.save();

  res
    .status(200)
    .json(new ApiResponse(200, "Email verified successfully", null));
});

export const sendResetPasswordOTP = AsynHandler(async (req, res) => {
  const { email } = req.body;

  if (!email) {
    res.status(400);
    throw new ApiError(400, "Please provide an email");
  }

  const user = await User.findOne({ email });

  if (!user) {
    res.status(404);
    throw new ApiError(404, "User not found");
  }

  const OTP = Math.floor(100000 + Math.random() * 900000);
  user.resetPasswordOtp = OTP;
  user.resetPasswordOtpExpiry = Date.now() + 5 * 60 * 1000; // 5 minutes

  await user.save();
  sendEmail(
    user.email,
    "Reset your password",
    `
    Your OTP for password reset is: ${OTP}
    This OTP is valid for 5 minutes.
      `,
  );
  res.status(200).json(new ApiResponse(200, "OTP sent successfully", null));
});

export const resetPassword = AsynHandler(async (req, res) => {
  const { email, otp, newPassword } = req.body;
  if (!email || !otp || !newPassword) {
    res.status(400);
    throw new ApiError(400, "Please fill all the fields");
  }

  const user = await User.findOne({ email }).select(
    "+resetPasswordOtp +resetPasswordOtpExpiry",
  );

  if (!user) {
    res.status(404);
    throw new ApiError(404, "User not found");
  }

  if (
    user.resetPasswordOtp !== otp ||
    user.resetPasswordOtpExpiry < Date.now()
  ) {
    res.status(400);
    throw new ApiError(400, "Invalid or expired OTP");
  }

  user.password = await User.hashPassword(newPassword);
  user.resetPasswordOtp = undefined;
  user.resetPasswordOtpExpiry = undefined;
  await user.save();

  res
    .status(200)
    .json(new ApiResponse(200, "Password reset successfully", null));
});

export const changePassword = AsynHandler(async (req, res) => {
  const { oldPassword, newPassword } = req.body;
  const { userId: loginUserId } = req.user;

  if (!oldPassword || !newPassword) {
    res.status(400);
    throw new ApiError(400, "Please provide old and new passwords");
  }

  const user = await User.findById(loginUserId).select("+password");

  if (!user) {
    res.status(404);
    throw new ApiError(404, "User not found");
  }

  const isMatch = await user.comparePassword(oldPassword);
  if (!isMatch) {
    res.status(400);
    throw new ApiError(400, "Invalid old password");
  }

  user.password = await User.hashPassword(newPassword);
  user.isFirstLogin = false;
  await user.save();

  res
    .status(200)
    .json(new ApiResponse(200, "Password changed successfully", null));
});

export const toggleFavorite = AsynHandler(async (req, res) => {
  const { foodId } = req.params;
  const { userId } = req.user;

  if (!foodId) {
    throw new ApiError(400, "Food ID is required");
  }

  const user = await User.findById(userId);
  if (!user) {
    throw new ApiError(404, "User not found");
  }

  const index = user.favorites.indexOf(foodId);
  if (index === -1) {
    user.favorites.push(foodId);
    await user.save();
    return res.status(200).json(new ApiResponse(200, "Added to favorites", { isFavorite: true }));
  } else {
    user.favorites.splice(index, 1);
    await user.save();
    return res.status(200).json(new ApiResponse(200, "Removed from favorites", { isFavorite: false }));
  }
});

export const getFavorites = AsynHandler(async (req, res) => {
  const { userId } = req.user;

  const user = await User.findById(userId).populate("favorites");
  if (!user) {
    throw new ApiError(404, "User not found");
  }

  res.status(200).json(new ApiResponse(200, "Favorites fetched successfully", user.favorites));
});

