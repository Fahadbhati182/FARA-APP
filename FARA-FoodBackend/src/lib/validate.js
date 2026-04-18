import { validationResult } from 'express-validator';

// Handle validation errors
const validate = (req, res, next) => {
  const errors = validationResult(req);
  console.log(errors)
  
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array().map(err => ({
        field: err.path,
        message: err.msg
      }))
    });
  }
  
  next();
};

export default validate;