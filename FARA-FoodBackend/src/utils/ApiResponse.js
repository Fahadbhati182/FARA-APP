class ApiResponse {
  constructor(statusCode = 200, message , data  ) {
    this.success = statusCode >= 200 && statusCode < 300;
    this.status = statusCode;
    this.message = message;
    this.data = data;
  }
}

export default ApiResponse;