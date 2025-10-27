-- Client Utility Functions
-- Helper functions for client-side operations

-- Format phone number
function FormatPhoneNumber(number)
    if not number then return '' end
    
    local formatted = tostring(number)
    local format = Config.PhoneNumberFormat
    
    -- Simple formatting based on config
    if #formatted == 7 then
        return formatted:sub(1, 3) .. '-' .. formatted:sub(4, 7)
    end
    
    return formatted
end

-- Validate phone number
function IsValidPhoneNumber(number)
    if not number then return false end
    
    local numStr = tostring(number):gsub('[^%d]', '')
    return #numStr == Config.PhoneNumberLength
end
