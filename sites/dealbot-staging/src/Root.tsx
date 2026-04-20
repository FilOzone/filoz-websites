import React from 'react'
import { BrowserRouter } from 'react-router-dom'
import { ThemeProvider } from '@/components/shared'
import App from './App'

import './index.css'

export function Root() {
  return (
    <React.StrictMode>
      <ThemeProvider>
        <BrowserRouter>
          <App />
        </BrowserRouter>
      </ThemeProvider>
    </React.StrictMode>
  )
}
