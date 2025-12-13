import './globals.css'
import { Inter } from 'next/font/google'
import { ClerkProvider } from '@clerk/nextjs'
import { ColorModeScript } from '@chakra-ui/react'
import { Providers } from './providers'
import customTheme from './theme'

export const metadata = {
  metadataBase: new URL('https://fantasy.razumau.net'),
  title: 'Fantasy',
  description:
    'Description',
}

const inter = Inter({
  variable: '--font-inter',
  subsets: ['latin', 'cyrillic-ext'],
  display: 'swap',
})

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <ClerkProvider>
      <html lang="en">
      <body className={inter.variable}>
        <ColorModeScript initialColorMode={customTheme.config.initialColorMode} />
        <Providers>{children}</Providers>
      </body>
      </html>
    </ClerkProvider>
  )
}
