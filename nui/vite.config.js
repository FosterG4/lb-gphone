import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path'

export default defineConfig({
  plugins: [vue()],
  base: './',
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    emptyOutDir: true,
    minify: 'esbuild',
    sourcemap: false,
    target: 'es2015',
    chunkSizeWarningLimit: 600,
    rollupOptions: {
      output: {
        entryFileNames: 'assets/[name].js',
        chunkFileNames: 'assets/[name].js',
        assetFileNames: 'assets/[name].[ext]',
        manualChunks: (id) => {
          // Vendor chunk for core dependencies
          if (id.includes('node_modules')) {
            if (id.includes('vue') || id.includes('vuex') || id.includes('vue-router')) {
              return 'vendor'
            }
            if (id.includes('vue-i18n')) {
              return 'i18n-vendor'
            }
            if (id.includes('lucide-vue-next')) {
              return 'icons'
            }
          }
          
          // Separate chunk for locale files
          if (id.includes('/locales/') && id.endsWith('.json')) {
            const locale = id.match(/\/locales\/(\w+)\.json/)?.[1]
            return locale ? locale : 'locales'
          }
          
          // Separate chunk for views/apps if they exist
          if (id.includes('/views/') || id.includes('/apps/')) {
            return 'apps'
          }
        }
      }
    }
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src')
    }
  },
  server: {
    port: 3000,
    strictPort: true
  }
})
