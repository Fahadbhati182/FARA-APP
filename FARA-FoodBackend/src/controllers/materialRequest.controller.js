import MaterialRequest from "../models/MaterialRequest.model.js";
import ApiError from "../utils/ApiError.js";
import ApiResponse from "../utils/ApiResponse.js";
import AsynHandler from "../utils/AsynHandler.js";

export const createMaterialRequest = AsynHandler(async (req, res) => {
  const { userId, role } = req.user;
  const { worker_name, stall_name, item_name, quantity, notes } = req.body;

  if (role !== "worker") {
    res.status(403);
    throw new ApiError(403, "Only workers can create material requests");
  }

  if (!item_name || !quantity || !worker_name) {
    res.status(400);
    throw new ApiError(400, "Missing required fields");
  }

  const request = await MaterialRequest.create({
    worker_id: userId,
    worker_name,
    stall_name,
    item_name,
    quantity,
    notes,
    status: "pending",
  });

  return res.status(201).json(new ApiResponse(201, "Material request created successfully", request));
});

export const getWorkerMaterialRequests = AsynHandler(async (req, res) => {
  const { userId } = req.user;

  const requests = await MaterialRequest.find({ worker_id: userId }).sort({ createdAt: -1 });

  return res.status(200).json(new ApiResponse(200, "Material requests fetched successfully", requests));
});

export const updateMaterialRequestStatus = AsynHandler(async (req, res) => {
  const { role } = req.user;
  const { id } = req.params;
  const { status } = req.body;

  if (role !== "admin") {
    res.status(403);
    throw new ApiError(403, "Only admins can update material request status");
  }

  const request = await MaterialRequest.findById(id);
  if (!request) {
    res.status(404);
    throw new ApiError(404, "Request not found");
  }

  request.status = status;
  await request.save();

  return res.status(200).json(new ApiResponse(200, "Material request status updated", request));
});
