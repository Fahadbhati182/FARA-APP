import Food from "../models/Food.model.js";
import ApiError from "../utils/ApiError.js";
import ApiResponse from "../utils/ApiResponse.js";
import AsynHandler from "../utils/AsynHandler.js";
import cloudinary from "cloudinary";

const uploadToCloudinary = (buffer) => {
  return new Promise((resolve, reject) => {
    const stream = cloudinary.v2.uploader.upload_stream(
      { folder: "fara-foods" },
      (error, result) => {
        if (error) {
          reject(error);
        } else {
          resolve(result.secure_url);
        }
      }
    );
    stream.end(buffer);
  });
};

export const createFood = AsynHandler(async (req, res) => {
  const { userId, role } = req.user;

  if (!userId) {
    res.status(401);
    throw new ApiError(401, "Unauthorized");
  }

  if (userId && role !== "admin") {
    res.status(403);
    throw new ApiError(403, "Forbidden: Admins only");
  }

  const { name, description, price, costPrice, category, isAvailable, isVeg, isBestSeller, prepTime, cookTime, totalTime } = req.body;

  if (!name || !description || price === undefined || !category) {
    res.status(400);
    throw new ApiError(400, "Please fill all required fields");
  }

  let finalImageUrl = "";
  if (req.file) {
    try {
      finalImageUrl = await uploadToCloudinary(req.file.buffer);
    } catch (err) {
      console.error(err);
      res.status(500);
      throw new ApiError(500, "Image upload failed");
    }
  } else if (req.body.image) {
    finalImageUrl = req.body.image;
  }

  const food = await Food.create({
    name,
    description,
    price,
    category,
    image: finalImageUrl,
    isAvailable: isAvailable !== undefined ? isAvailable : true,
    isVeg: isVeg !== undefined ? isVeg : true,
    isBestSeller: isBestSeller !== undefined ? isBestSeller : false,
    prepTime: prepTime !== undefined ? Number(prepTime) : 15,
    cookTime: cookTime !== undefined ? Number(cookTime) : 15,
    totalTime: totalTime !== undefined ? Number(totalTime) : 30,
    costPrice: costPrice !== undefined ? Number(costPrice) : 0,
  });

  if (!food) {
    res.status(500);
    throw new ApiError(500, "Failed to create food item");
  }

  return res.status(201).json(new ApiResponse(201, "Food created successfully", food));
});

export const getAllFoods = AsynHandler(async (req, res) => {
  const foods = await Food.find();
  return res.status(200).json(new ApiResponse(200, "Foods fetched successfully", foods));
});

export const getFoodById = AsynHandler(async (req, res) => {
  const { id } = req.params;
  const food = await Food.findById(id);

  if (!food) {
    res.status(404);
    throw new ApiError(404, "Food item not found");
  }

  return res.status(200).json(new ApiResponse(200, "Food fetched successfully", food));
});

export const updateFood = AsynHandler(async (req, res) => {
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

  const { name, description, price, costPrice, category, isAvailable, isVeg, isBestSeller, prepTime, cookTime, totalTime } = req.body;

  const food = await Food.findById(id);

  if (!food) {
    res.status(404);
    throw new ApiError(404, "Food item not found");
  }

  let finalImageUrl = food.image;
  if (req.file) {
    try {
      finalImageUrl = await uploadToCloudinary(req.file.buffer);
    } catch (err) {
      console.error(err);
      res.status(500);
      throw new ApiError(500, "Image upload failed");
    }
  } else if (req.body.image !== undefined) {
    finalImageUrl = req.body.image;
  }

  food.name = name ?? food.name;
  food.description = description ?? food.description;
  food.price = price ?? food.price;
  food.category = category ?? food.category;
  food.image = finalImageUrl;
  food.isAvailable = isAvailable ?? food.isAvailable;
  food.isVeg = isVeg ?? food.isVeg;
  food.isBestSeller = isBestSeller ?? food.isBestSeller;
  if (prepTime !== undefined) food.prepTime = Number(prepTime);
  if (cookTime !== undefined) food.cookTime = Number(cookTime);
  if (totalTime !== undefined) food.totalTime = Number(totalTime);
  if (costPrice !== undefined) food.costPrice = Number(costPrice);

  await food.save();

  return res.status(200).json(new ApiResponse(200, "Food updated successfully", food));
});

export const deleteFood = AsynHandler(async (req, res) => {
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

  const food = await Food.findByIdAndDelete(id);

  if (!food) {
    res.status(404);
    throw new ApiError(404, "Food item not found");
  }

  return res.status(200).json(new ApiResponse(200, "Food deleted successfully", null));
});
