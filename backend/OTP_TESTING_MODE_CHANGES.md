# OTP Testing Mode Changes for Render Production

## Summary
This document summarizes the changes made to enable testing-mode OTP (always "123456") in Render production environment.

## Changes Made

### 1. Updated OTP Generation (`apps/accounts/otp_service.py`)
- **`generate_otp()`** now returns `"123456"` when:
  - `RENDER` environment variable is set to `"true"`
  - `DEBUG` is `False`
- In local development, it continues to generate random 6-digit OTPs

### 2. Updated OTP Sending (`apps/accounts/otp_service.py`)
- **`send_otp()`** is now a no-op placeholder for testing
- Prints OTP for debugging: `print(f"OTP for debugging: {otp_code}")`
- No actual SMS/Email sending in production (prevents Twilio/email credential errors)

### 3. Fixed MFA Service (`apps/accounts/services/mfa_service.py`)
- Fixed incorrect parameter order in `OTPService.send_otp()` calls
- Fixed incorrect parameter order in `OTPService.verify_otp()` calls
- Fixed return value handling (now correctly unpacks tuple)

## Environment Variable Setup

**Required in Render Dashboard:**
- Key: `RENDER`
- Value: `true`

This will be automatically detected by the code.

## Testing Instructions

### Student & Faculty Signup:
1. Enter registration details
2. OTP will always be: **123456**
3. Login should succeed

### Forgot Password:
1. Request password reset
2. OTP will always be: **123456**
3. Password reset should work

## Files Modified

1. `backend/apps/accounts/otp_service.py`
   - Updated `generate_otp()` method
   - Updated `send_otp()` method

2. `backend/apps/accounts/services/mfa_service.py`
   - Fixed parameter order in OTP service calls
   - Fixed return value handling

## Deployment

After code changes:
```bash
git add .
git commit -m "Enable testing-mode OTP (123456) for Render production"
git push
```

Render will auto-deploy with the new changes.

## Notes

- All OTP generation now uses `OTPService.generate_otp()` consistently
- No hardcoded OTP values found
- Registration, login, and password-reset flows all use the updated function
- MFA (Multi-Factor Authentication) flows also use the updated function

