// NUI Communication Utility
// Handles communication between Vue and Lua

const resourceName = window.location.hostname === 'localhost' 
    ? 'fivem-smartphone-nui' 
    : GetParentResourceName()

export async function nuiCallback(action, data = {}) {
    try {
        const response = await fetch(`https://${resourceName}/${action}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
        })
        
        return await response.json()
    } catch (error) {
        console.error(`NUI Callback Error [${action}]:`, error)
        return { success: false, error: 'CALLBACK_FAILED' }
    }
}

function GetParentResourceName() {
    // In FiveM NUI, the hostname is the resource name
    return window.location.hostname || 'fivem-smartphone-nui'
}

// Alias for compatibility
export const fetchNui = nuiCallback
export const postNUI = nuiCallback

export { resourceName }
