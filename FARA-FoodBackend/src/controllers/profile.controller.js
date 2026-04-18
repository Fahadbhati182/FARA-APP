import User from "../models/User.model.js";
import ApiError from "../utils/ApiError.js";
import ApiResponse from "../utils/ApiResponse.js";
import AsynHandler from "../utils/AsynHandler.js";
import cloudinary from "cloudinary";

/**
 * @desc    Get all addresses of the user
 * @route   GET /api/profile/addresses
 * @access  Private
 */
export const getAddresses = AsynHandler(async (req, res) => {
  const { userId } = req.user;
  const user = await User.findById(userId);

  if (!user) {
    throw new ApiError(404, "User not found");
  }

  return res
    .status(200)
    .json(new ApiResponse(200, "Addresses fetched successfully", user.addresses));
});

/**
 * @desc    Create a new address
 * @route   POST /api/profile/addresses
 * @access  Private
 */
export const createAddress = AsynHandler(async (req, res) => {
  const { userId } = req.user;
  const { label, addressLine, city, state, pincode, lat, lng } = req.body;

  if (!addressLine) {
    throw new ApiError(400, "Address line is required");
  }

  const user = await User.findById(userId);
  if (!user) {
    throw new ApiError(404, "User not found");
  }

  const newAddress = {
    label,
    addressLine,
    city,
    state,
    pincode,
    location: (lat && lng) ? { lat, lng } : undefined
  };

  user.addresses.push(newAddress);
  
  // If it's the first address, set it as default
  if (user.addresses.length === 1) {
    user.defaultAddressId = user.addresses[0]._id;
  }

  await user.save();

  return res
    .status(201)
    .json(new ApiResponse(201, "Address created successfully", user.addresses[user.addresses.length - 1]));
});

/**
 * @desc    Update an address
 * @route   PUT /api/profile/addresses/:id
 * @access  Private
 */
export const updateAddress = AsynHandler(async (req, res) => {
  const { userId } = req.user;
  const { id } = req.params;
  const { label, addressLine, city, state, pincode, lat, lng } = req.body;

  const user = await User.findById(userId);
  if (!user) {
    throw new ApiError(404, "User not found");
  }

  const address = user.addresses.id(id);
  if (!address) {
    throw new ApiError(404, "Address not found");
  }

  if (label) address.label = label;
  if (addressLine) address.addressLine = addressLine;
  if (city) address.city = city;
  if (state) address.state = state;
  if (pincode) address.pincode = pincode;
  if (lat && lng) address.location = { lat, lng };

  await user.save();

  return res
    .status(200)
    .json(new ApiResponse(200, "Address updated successfully", address));
});

/**
 * @desc    Delete an address
 * @route   DELETE /api/profile/addresses/:id
 * @access  Private
 */
export const deleteAddress = AsynHandler(async (req, res) => {
  const { userId } = req.user;
  const { id } = req.params;

  const user = await User.findById(userId);
  if (!user) {
    throw new ApiError(404, "User not found");
  }

  user.addresses = user.addresses.filter(addr => addr._id.toString() !== id);
  
  // If default address was deleted, reset default
  if (user.defaultAddressId && user.defaultAddressId.toString() === id) {
    user.defaultAddressId = user.addresses.length > 0 ? user.addresses[0]._id : undefined;
  }

  await user.save();

  return res
    .status(200)
    .json(new ApiResponse(200, "Address deleted successfully", null));
});

/**
 * @desc    Set default address
 * @route   PATCH /api/profile/addresses/default/:id
 * @access  Private
 */
export const setDefaultAddress = AsynHandler(async (req, res) => {
  const { userId } = req.user;
  const { id } = req.params;

  const user = await User.findById(userId);
  if (!user) {
    throw new ApiError(404, "User not found");
  }

  const address = user.addresses.id(id);
  if (!address) {
    throw new ApiError(404, "Address not found");
  }

  user.defaultAddressId = id;
  await user.save();

  return res
    .status(200)
    .json(new ApiResponse(200, "Default address set successfully", { defaultAddressId: id }));
});

/**
 * @desc    Update user profile (image, name, phone)
 * @route   POST /api/profile/update
 * @access  Private
 */
export const updateProfile = AsynHandler(async (req, res) => {
  const { userId } = req.user;
  const { name, phone } = req.body;

  const user = await User.findById(userId);
  if (!user) {
    throw new ApiError(404, "User not found");
  }

  if (name) user.name = name;
  if (phone && phone !== user.phone) {
    const existingPhoneUser = await User.findOne({ phone });
    if (existingPhoneUser) {
      throw new ApiError(400, "Phone number already in use by another account");
    }
    user.phone = phone;
  }

  // Handle image upload if present
  if (req.file) {
    try {
      // Upload to Cloudinary from memory
      const result = await new Promise((resolve, reject) => {
        const uploadStream = cloudinary.v2.uploader.upload_stream(
          { folder: "profile_images" },
          (error, result) => {
            if (error) reject(error);
            else resolve(result);
          }
        );
        uploadStream.end(req.file.buffer);
      });

      user.profileImage = result.secure_url;
    } catch (error) {
      throw new ApiError(500, "Image upload failed: " + error.message);
    }
  }

  await user.save();

  return res
    .status(200)
    .json(new ApiResponse(200, "Profile updated successfully", user));
});
