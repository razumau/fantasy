import './globals.css'
import { Inter } from 'next/font/google'
import { ClerkProvider } from '@clerk/nextjs'
import { Providers } from './providers'

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
        <Providers>{children}</Providers>
      </body>
      </html>
    </ClerkProvider>
  )
}
