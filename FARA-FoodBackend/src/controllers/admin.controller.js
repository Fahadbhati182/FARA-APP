import jwt from "jsonwebtoken";
import { sendEmail } from "../lib/nodemailer.js";
import User from "../models/User.model.js";
import Order from "../models/Order.model.js";
import MaterialRequest from "../models/MaterialRequest.model.js";
import Outlet from "../models/Outlet.model.js";
import ApiError from "../utils/ApiError.js";
import ApiResponse from "../utils/ApiResponse.js";
import AsynHandler from "../utils/AsynHandler.js";

export const adminLogin = AsynHandler(async (req, res) => {
  const { email, password, role } = req.body;

  console.log(email, password, role, "In admin login");

  if (role !== "admin") {
    throw new ApiError(403, "Forbidden");
  }

  if (!email || !password) {
    throw new ApiError(400, "Please fill all the fields");
  }

  const cleanEmail = email.trim().toLowerCase();

  if (
    cleanEmail !== process.env.ADMIN_EMAIL ||
    password !== process.env.ADMIN_PASSWORD
  ) {
    throw new ApiError(401, "Invalid credentials");
  }

  // Create a minimal admin payload
  const adminData = {
    userId: "admin",
    email: process.env.ADMIN_EMAIL,
    role: "admin",
  };

  // Generate JWT manually (since no DB user)
  const token = jwt.sign(adminData, process.env.JWT_SECRET, {
    expiresIn: "7d",
  });

  res.cookie("token", token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    maxAge: 7 * 24 * 60 * 60 * 1000,
  });

  res.status(200).json(
    new ApiResponse(200, "Admin logged in successfully", {
      token,
      user: adminData,
    }),
  );
});

export const addWorker = AsynHandler(async (req, res) => {
  const { userId, role } = req.user;

  if (!userId) {
    res.status(401);
    throw new ApiError(401, "Unauthorized");
  }

  if (userId && role !== "admin") {
    res.status(403);
    throw new ApiError(403, "Forbidden");
  }

  const { name, email, password, phone, address, outlets } = req.body;

  if ([name, email, password, phone, address].some((field) => !field)) {
    res.status(400);
    throw new ApiError(400, "All fields are required");
  }

  const existingWorker = await User.findOne({ email });

  if (existingWorker) {
    res.status(400);
    throw new ApiError(400, "Worker with this email already exists");
  }

  const hashPassword = await User.hashPassword(password);

  const worker = await User.create({
    name,
    email,
    password: hashPassword,
    phone,
    address,
    role: "worker",
  });

  if (!worker) {
    res.status(500);
    throw new ApiError(500, "Failed to create worker");
  }

  // Assign worker to given outlets
  if (outlets && Array.isArray(outlets) && outlets.length > 0) {
    // Sync the first assigned outlet name to the user profile
    const firstOutlet = await Outlet.findById(outlets[0]);
    if (firstOutlet) {
      worker.stall_name = firstOutlet.name;
      await worker.save();
    }

    await Outlet.updateMany(
      { _id: { $in: outlets } },
      { $addToSet: { workers: worker._id } },
    );
  }

  await sendEmail(
    worker.email,
    "Welcome to FARA",
    `
    Welcome ${worker.name}! You have been added as a worker.
    Please log in to your account to view and manage your tasks.
    Also change your password after logging in for the first time.

    Your Credentials:
    Email: ${worker.email}
    Password: ${password}
    
    `,
  );

  return res
    .status(201)
    .json(new ApiResponse(201, "Worker created successfully", worker));
});

export const updateWorker = AsynHandler(async (req, res) => {
  const { userId, role } = req.user;
  const { workerId } = req.params;

  if (!userId) {
    res.status(401);
    throw new ApiError(401, "Unauthorized");
  }

  if (userId && role !== "admin") {
    res.status(403);
    throw new ApiError(403, "Forbidden");
  }

  const { name, email, password, phone, address, outlets } = req.body;

  const worker = await User.findById(workerId);
  if (!worker) {
    res.status(404);
    throw new ApiError(404, "Worker not found");
  }

  worker.name = name || worker.name;
  worker.email = email || worker.email;
  worker.phone = phone || worker.phone;
  worker.address = address || worker.address;

  if (password) {
    worker.password = await User.hashPassword(password);
  }

  await worker.save();

  // Sync Outlets list:
  if (outlets && Array.isArray(outlets)) {
    // 1. Remove this worker from ALL outlets first
    await Outlet.updateMany(
      { workers: workerId },
      { $pull: { workers: workerId } },
    );
    // 2. Add this worker to the newly selected outlets
    if (outlets.length > 0) {
      // Sync the first assigned outlet name to the user profile
      const firstOutlet = await Outlet.findById(outlets[0]);
      if (firstOutlet) {
        worker.stall_name = firstOutlet.name;
        await worker.save();
      }

      await Outlet.updateMany(
        { _id: { $in: outlets } },
        { $addToSet: { workers: workerId } },
      );
    }
  }

  return res
    .status(200)
    .json(new ApiResponse(200, "Worker updated successfully", worker));
});

export const removeWorker = AsynHandler(async (req, res) => {
  const { userId, role } = req.user;

  if (!userId) {
    res.status(401);
    throw new ApiError(401, "Unauthorized");
  }

  if (userId && role !== "admin") {
    res.status(403);
    throw new ApiError(403, "Forbidden");
  }

  const { workerId } = req.params;

  const worker = await User.findByIdAndDelete(workerId);

  if (!worker) {
    res.status(404);
    throw new ApiError(404, "Worker not found");
  }

  // Ensure they are removed from any assigned outlets
  await Outlet.updateMany(
    { workers: workerId },
    { $pull: { workers: workerId } },
  );

  return res
    .status(200)
    .json(new ApiResponse(200, "Worker removed successfully", null));
});

export const getAllWorkers = AsynHandler(async (req, res) => {
  const workers = await User.aggregate([
    { $match: { role: "worker" } },
    {
      $lookup: {
        from: "outlets",
        localField: "_id",
        foreignField: "workers",
        as: "assignedOutlets",
      },
    },
  ]);

  return res
    .status(200)
    .json(new ApiResponse(200, "Workers retrieved successfully", workers));
});

export const getWorkerById = AsynHandler(async (req, res) => {
  const { workerId } = req.params;

  const worker = await User.findById(workerId);

  if (!worker) {
    res.status(404);
    throw new ApiError(404, "Worker not found");
  }

  return res
    .status(200)
    .json(new ApiResponse(200, "Worker retrieved successfully", worker));
});

// --- Auditing & Dashboard ---

export const getAdminDashboardStats = AsynHandler(async (req, res) => {
  const { role } = req.user;
  if (role !== "admin") {
    throw new ApiError(403, "Forbidden: Admin access only");
  }

  try {
    const today = new Date();
    // Use a slightly larger window (start of yesterday UTC) to ensure "today" local is covered,
    // or set it to 00:00:00 local if possible. For India (+5:30), today starts at 18:30 yesterday UTC.
    today.setUTCHours(0, 0, 0, 0); 
    today.setHours(today.getHours() - 6); // Offset by 6 hours to cover GMT+5:30 midnight safely

    // 1. Total Orders Today
    const totalOrdersToday = await Order.countDocuments({
      createdAt: { $gte: today },
    });

    // 2. Total Revenue Today
    const revenueTodayResult = await Order.aggregate([
      { $match: { createdAt: { $gte: today }, status: "completed" } },
      { $group: { _id: null, total: { $sum: "$total" } } },
    ]);
    const totalRevenueToday =
      revenueTodayResult.length > 0 ? revenueTodayResult[0].total : 0;

    // 3. Pending Orders Count
    const pendingOrders = await Order.countDocuments({ status: "pending" });

    // 4. Revenue by Stall (Today)
    const stallRevenue = await Order.aggregate([
      { $match: { createdAt: { $gte: today }, status: "completed" } },
      {
        $group: {
          _id: "$stall_name",
          orders: { $sum: 1 },
          revenue: { $sum: "$total" },
        },
      },
      { $sort: { revenue: -1 } },
    ]);

    const stallStats = stallRevenue.map((s) => ({
      stall: s._id || "Unnamed",
      orders: s.orders || 0,
      revenue: s.revenue || 0,
    }));

    // 5. Recent Orders
    const recentOrders = await Order.find()
      .populate("customer", "name email phone")
      .sort({ createdAt: -1 })
      .limit(5);

    // 6. Revenue by Source (Today)
    const sourceRevenue = await Order.aggregate([
      { $match: { createdAt: { $gte: today }, status: "completed" } },
      {
        $group: {
          _id: "$source",
          revenue: { $sum: "$total" },
        },
      },
    ]);

    const sourceStats = {
      app: 0,
      zomato: 0,
      swiggy: 0,
      offline: 0,
    };
    sourceRevenue.forEach((s) => {
      const sourceKey = s._id || 'app'; // Default to app if source is null
      if (sourceStats.hasOwnProperty(sourceKey)) {
        sourceStats[sourceKey] = s.revenue;
      } else {
        sourceStats[sourceKey] = s.revenue;
      }
    });

    const dashboardStats = {
      totalOrdersToday,
      totalRevenueToday,
      pendingOrders,
      stallStats,
      recentOrders,
      sourceStats,
    };

    console.log("Outgoing Dashboard Stats:", JSON.stringify(dashboardStats, null, 2));

    return res.status(200).json(
      new ApiResponse(200, "Dashboard stats fetched", dashboardStats),
    );
  } catch (error) {
    console.error("Dashboard Stats Error:", error);
    throw new ApiError(500, error.message || "Failed to fetch dashboard stats");
  }
});

export const recordExternalOrder = AsynHandler(async (req, res) => {
  const { role } = req.user;
  if (role !== "admin" && role !== "worker") {
    throw new ApiError(403, "Forbidden: Admin or Worker access only");
  }

  const { source, total, stall_name, location, items } = req.body;

  if (!source || !total || !stall_name) {
    throw new ApiError(400, "Source, total and stall name are required");
  }

  const order = await Order.create({
    customer_name: `${source.toUpperCase()} Order`,
    customer: "60d000000000000000000000", // Placeholder ID for external orders
    location: location || "External Platform",
    stall_name,
    items: items || [],
    total,
    order_type: "takeaway",
    source,
    status: "completed",
    payment_1: total,
    payment_1_at: new Date(),
  });

  return res
    .status(201)
    .json(new ApiResponse(201, "External order recorded", order));
});

export const getAdminAllOrders = AsynHandler(async (req, res) => {
  const { role } = req.user;
  if (role !== "admin") {
    throw new ApiError(403, "Forbidden: Admin access only");
  }

  const orders = await Order.find()
    .populate("customer", "name email phone")
    .sort({ createdAt: -1 });
  return res
    .status(200)
    .json(new ApiResponse(200, "All orders fetched", orders));
});

export const getAdminAllRequests = AsynHandler(async (req, res) => {
  const { role } = req.user;
  if (role !== "admin") {
    throw new ApiError(403, "Forbidden: Admin access only");
  }

  const requests = await MaterialRequest.find().sort({ createdAt: -1 });
  return res
    .status(200)
    .json(new ApiResponse(200, "All material requests fetched", requests));
});

export const getAdminAnalytics = AsynHandler(async (req, res) => {
  const { role } = req.user;
  if (role !== "admin") {
    throw new ApiError(403, "Forbidden: Admin access only");
  }

  const { period } = req.query;
  const startDate = new Date();

  if (period === "This Week") {
    startDate.setDate(startDate.getDate() - startDate.getDay());
  } else if (period === "This Month") {
    startDate.setDate(1);
  }
  startDate.setUTCHours(0, 0, 0, 0);
  startDate.setHours(startDate.getHours() - 6); // Safe offset for local "Today"

  // Aggregated Item Stats
  const itemStats = await Order.aggregate([
    { $match: { createdAt: { $gte: startDate }, status: { $ne: "rejected" } } },
    { $unwind: "$items" },
    {
      $lookup: {
        from: "foods",
        localField: "items.name",
        foreignField: "name",
        as: "foodDetails",
      },
    },
    {
      $addFields: {
        costPrice: { $ifNull: [{ $arrayElemAt: ["$foodDetails.costPrice", 0] }, 0] },
      },
    },
    {
      $group: {
        _id: "$items.name",
        qty: { $sum: "$items.qty" },
        revenue: { $sum: { $multiply: ["$items.qty", "$items.price"] } },
        profit: {
          $sum: {
            $multiply: [
              "$items.qty",
              { $subtract: ["$items.price", "$costPrice"] },
            ],
          },
        },
      },
    },
    { $sort: { qty: -1 } },
    { $project: { name: "$_id", _id: 0, qty: 1, revenue: 1, profit: 1 } },
  ]);

  // Add revenue from orders that don't have items (Manual recording)
  const nonItemRevenueResult = await Order.aggregate([
    { $match: { createdAt: { $gte: startDate }, status: { $ne: "rejected" }, items: { $size: 0 } } },
    { $group: { _id: null, revenue: { $sum: "$total" } } }
  ]);
  
  if (nonItemRevenueResult.length > 0 && nonItemRevenueResult[0].revenue > 0) {
    itemStats.push({
      name: "Other (Manual Entry)",
      qty: 0,
      revenue: nonItemRevenueResult[0].revenue
    });
  }

  // Traffic by Location
  const locationStats = await Order.aggregate([
    { $match: { createdAt: { $gte: startDate }, status: { $ne: "rejected" } } },
    {
      $group: {
        _id: "$location",
        orders: { $sum: 1 },
        revenue: { $sum: "$total" },
      },
    },
    { $sort: { orders: -1 } },
    { $project: { location: "$_id", _id: 0, orders: 1, revenue: 1 } },
  ]);

  return res.status(200).json(
    new ApiResponse(200, "Analytics fetched", {
      itemStats,
      locationStats,
    }),
  );
});
