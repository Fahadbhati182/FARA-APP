import { sendEmail } from "../lib/nodemailer.js";
import Outlet from "../models/Outlet.model.js";
import User from "../models/User.model.js";
import ApiError from "../utils/ApiError.js";
import ApiResponse from "../utils/ApiResponse.js";
import AsynHandler from "../utils/AsynHandler.js";

export const createOutlet = AsynHandler(async (req, res) => {
  const { userId, role } = req.user;

  if (!userId) {
    res.status(401);
    throw new ApiError(401, "Unauthorized");
  }

  if (userId && role !== "admin") {
    res.status(403);
    throw new ApiError(403, "Forbidden");
  }
  const { name, location, openingHours } = req.body;
  let { workers } = req.body;

  if (workers && !Array.isArray(workers)) {
    workers = [workers];
  }

  if (!name || !location || !openingHours || !workers) {
    throw new ApiError(400, "Please fill all required fields");
  }
  // const filePath = req?.file.path;

  if (!name || !location || !openingHours || !workers) {
    res.status(400);
    throw new ApiError(400, "Please fill all the fields");
  }

  // let imageUrl;
  // if (filePath) {
  //   const uploads = await cloudinary.uploader.upload(filePath);
  //   imageUrl = uploads.secure_url;
  // }

  const outlet = await Outlet.create({
    name,
    location,
    img: "imageUrl",
    openingHours,
    workers,
  });

  if (!outlet) {
    res.status(500);
    throw new ApiError(500, "Failed to create outlet");
  }

  res
    .status(201)
    .json(new ApiResponse(201, "Outlet created successfully", outlet));
});

export const getOutlets = AsynHandler(async (req, res) => {
  const outlets = await Outlet.find().populate("workers", "name email phone");
  res
    .status(200)
    .json(new ApiResponse(200, "Outlets fetched successfully", outlets));
});

export const getOutletById = AsynHandler(async (req, res) => {
  const { id } = req.params;
  const outlet = await Outlet.findById(id).populate(
    "workers",
    "name email phone",
  );

  if (!outlet) {
    res.status(404);
    throw new ApiError(404, "Outlet not found");
  }

  res
    .status(200)
    .json(new ApiResponse(200, "Outlet fetched successfully", outlet));
});

export const updateOutlet = AsynHandler(async (req, res) => {
  const { userId, role } = req.user;
  const { id } = req.params;

  if (!userId) {
    res.status(401);
    throw new ApiError(401, "Unauthorized");
  }

  if (userId && role !== "admin") {
    res.status(403);
    throw new ApiError(403, "Forbidden");
  }

  const { name, location, openingHours, workers } = req.body;

  const outlet = await Outlet.findById(id);

  if (!outlet) {
    res.status(404);
    throw new ApiError(404, "Outlet not found");
  }

  outlet.name = name || outlet.name;
  outlet.location = location || outlet.location;
  outlet.openingHours = openingHours || outlet.openingHours;
  outlet.workers = workers || outlet.workers;

  await outlet.save();

  res
    .status(200)
    .json(new ApiResponse(200, "Outlet updated successfully", outlet));
});

export const deleteOutlet = AsynHandler(async (req, res) => {
  const { userId, role } = req.user;
  const { id } = req.params;

  if (!userId) {
    res.status(401);
    throw new ApiError(401, "Unauthorized");
  }

  if (userId && role !== "admin") {
    res.status(403);
    throw new ApiError(403, "Forbidden");
  }

  const outlet = await Outlet.findByIdAndDelete(id);

  if (!outlet) {
    res.status(404);
    throw new ApiError(404, "Outlet not found");
  }

  res
    .status(200)
    .json(new ApiResponse(200, "Outlet deleted successfully", null));
});
