import express from "express";
import {
  getCurrentUser,
  isAuthenticated,
  loginUser,
  logoutUser,
  registerUser,
  resetPassword,
  sendResetPasswordOTP,
  sendVerifyEmailOTP,
  verifyEmailOTP,
  changePassword,
  getFavorites,
  toggleFavorite,
} from "../controllers/auth.controller.js";
import authUser from "../middleware/authUser.js";
import { body } from "express-validator";
import validate from "../lib/validate.js";

const userRouter = express.Router();

const registerValidation = [
  body('name').trim().isLength({ min: 3 }).withMessage('Name must be at least 3 characters'),
  body('email').isEmail().withMessage('Please provide a valid email'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  validate
];

const loginValidation = [
  body('email').isEmail().withMessage('Please provide a valid email'),
  body('password').notEmpty().withMessage('Password is required'),
  validate
];

userRouter.post("/register",registerValidation, registerUser);
userRouter.post("/login", loginValidation, loginUser);
userRouter.get("/profile",authUser, getCurrentUser);
userRouter.get("/is-authenticated", authUser, isAuthenticated)
userRouter.get("/logout", logoutUser);
userRouter.get("/send-verify-otp", authUser, sendVerifyEmailOTP);
userRouter.post("/verify-otp", authUser, verifyEmailOTP);
userRouter.post("/send-reset-password-otp", sendResetPasswordOTP);
userRouter.post("/reset-password", resetPassword);
userRouter.patch("/change-password", authUser, changePassword);
userRouter.get("/favorites", authUser, getFavorites);
userRouter.post("/toggle-favorite/:foodId", authUser, toggleFavorite);


export default userRouter;