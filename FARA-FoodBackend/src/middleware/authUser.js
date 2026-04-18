import jsonwebtoken from "jsonwebtoken";
import ApiError from "../utils/ApiError.js";

const authUser = async (req, res, next) => {
  const token = req?.cookies?.token || req?.headers?.authorization?.split(" ")[1];
  
  if (!token) {
    return res.status(401).json({
      success: false,
      message: "Unauthorized: No token provided"
    });
  }
  try {
    const decoded = jsonwebtoken.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    console.error("JWT verification failed:", error);
    return res.status(401).json({
      success: false,
      message: "Unauthorized: Invalid token"
    });
  }
};


export default authUser;  
