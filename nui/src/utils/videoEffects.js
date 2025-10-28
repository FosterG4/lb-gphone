// Video Effects Utilities for Modish App
// Handles filter application, TTS generation, and music track metadata

/**
 * Available video filters
 */
export const VIDEO_FILTERS = {
  none: {
    name: 'None',
    cssFilter: 'none'
  },
  bw: {
    name: 'Black & White',
    cssFilter: 'grayscale(100%)'
  },
  sepia: {
    name: 'Sepia',
    cssFilter: 'sepia(100%)'
  },
  vintage: {
    name: 'Vintage',
    cssFilter: 'sepia(50%) contrast(120%) brightness(90%)'
  },
  cool: {
    name: 'Cool',
    cssFilter: 'hue-rotate(180deg) saturate(150%)'
  },
  warm: {
    name: 'Warm',
    cssFilter: 'hue-rotate(20deg) saturate(130%) brightness(110%)'
  },
  vibrant: {
    name: 'Vibrant',
    cssFilter: 'saturate(200%) contrast(120%)'
  }
};

/**
 * Apply CSS filter to video element
 * @param {HTMLVideoElement} videoElement - The video element to apply filter to
 * @param {string} filterName - Name of the filter from VIDEO_FILTERS
 */
export function applyVideoFilter(videoElement, filterName) {
  if (!videoElement) return;
  
  const filter = VIDEO_FILTERS[filterName] || VIDEO_FILTERS.none;
  videoElement.style.filter = filter.cssFilter;
}

/**
 * Available music tracks for videos
 */
export const MUSIC_TRACKS = {
  track1: {
    name: 'Upbeat Pop',
    url: '/sounds/music/upbeat-pop.mp3',
    duration: 60
  },
  track2: {
    name: 'Chill Vibes',
    url: '/sounds/music/chill-vibes.mp3',
    duration: 60
  },
  track3: {
    name: 'Hip Hop Beat',
    url: '/sounds/music/hip-hop-beat.mp3',
    duration: 60
  },
  track4: {
    name: 'Electronic Dance',
    url: '/sounds/music/electronic-dance.mp3',
    duration: 60
  },
  track5: {
    name: 'Acoustic Guitar',
    url: '/sounds/music/acoustic-guitar.mp3',
    duration: 60
  }
};

/**
 * Get music track info by ID
 * @param {string} trackId - The track ID
 * @returns {object|null} Track info or null if not found
 */
export function getMusicTrack(trackId) {
  return MUSIC_TRACKS[trackId] || null;
}

/**
 * TTS (Text-to-Speech) configuration
 * Note: Actual TTS generation should be done server-side or via API
 * This is just for metadata storage
 */
export const TTS_CONFIG = {
  maxLength: 200,
  defaultVoice: 'en-US-Standard-A',
  supportedLanguages: ['en-US', 'es-ES', 'fr-FR', 'de-DE', 'ja-JP']
};

/**
 * Validate TTS text
 * @param {string} text - The text to validate
 * @returns {object} Validation result with success and message
 */
export function validateTTSText(text) {
  if (!text || typeof text !== 'string') {
    return {
      success: false,
      message: 'TTS text is required'
    };
  }
  
  const trimmed = text.trim();
  
  if (trimmed.length === 0) {
    return {
      success: false,
      message: 'TTS text cannot be empty'
    };
  }
  
  if (trimmed.length > TTS_CONFIG.maxLength) {
    return {
      success: false,
      message: `TTS text is too long (max ${TTS_CONFIG.maxLength} characters)`
    };
  }
  
  return {
    success: true,
    text: trimmed
  };
}

/**
 * Generate TTS metadata for storage
 * @param {string} text - The text for TTS
 * @param {string} voice - Voice ID (optional)
 * @param {string} language - Language code (optional)
 * @returns {object} TTS metadata object
 */
export function generateTTSMetadata(text, voice = null, language = 'en-US') {
  return {
    text: text.trim(),
    voice: voice || TTS_CONFIG.defaultVoice,
    language: language,
    timestamp: Date.now()
  };
}

/**
 * Create video effects metadata object for storage
 * @param {object} options - Effect options
 * @param {string} options.filter - Filter name
 * @param {object} options.tts - TTS configuration
 * @param {string} options.music - Music track ID
 * @returns {object} Complete effects metadata
 */
export function createVideoEffectsMetadata(options = {}) {
  const metadata = {};
  
  if (options.filter && options.filter !== 'none') {
    metadata.filter = options.filter;
  }
  
  if (options.tts && options.tts.text) {
    metadata.tts = generateTTSMetadata(
      options.tts.text,
      options.tts.voice,
      options.tts.language
    );
  }
  
  if (options.music) {
    const track = getMusicTrack(options.music);
    if (track) {
      metadata.music = {
        trackId: options.music,
        name: track.name,
        url: track.url
      };
    }
  }
  
  return metadata;
}

/**
 * Parse video effects metadata from JSON
 * @param {string} json - JSON string of effects metadata
 * @returns {object|null} Parsed metadata or null if invalid
 */
export function parseVideoEffectsMetadata(json) {
  if (!json) return null;
  
  try {
    return JSON.parse(json);
  } catch (error) {
    console.error('Failed to parse video effects metadata:', error);
    return null;
  }
}

