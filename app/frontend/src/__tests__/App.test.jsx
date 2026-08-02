import { describe, it, expect, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { expect as chaiExpect } from '@testing-library/jest-dom'
import App from '../App'

// Extend expect with jest-dom matchers
chaiExpect.extend(expect)

describe('App', () => {
  beforeEach(() => {
    render(
      <BrowserRouter>
        <App />
      </BrowserRouter>
    )
  })

  it('renders the header with logo', () => {
    const logoElement = screen.getByText(/shopsimple/i)
    expect(logoElement).toBeInTheDocument()
  })

  it('renders navigation links', () => {
    expect(screen.getByText(/home/i)).toBeInTheDocument()
    expect(screen.getByText(/products/i)).toBeInTheDocument()
    expect(screen.getByText(/cart/i)).toBeInTheDocument()
    expect(screen.getByText(/health/i)).toBeInTheDocument()
  })

  it('renders the home page by default', () => {
    expect(screen.getByText(/welcome to shopsimple/i)).toBeInTheDocument()
  })

  it('has a products link in navigation', () => {
    const productsLink = screen.getByRole('link', { name: /products/i })
    expect(productsLink).toHaveAttribute('href', '/products')
  })

  it('has a cart link in navigation', () => {
    const cartLink = screen.getByRole('link', { name: /cart/i })
    expect(cartLink).toHaveAttribute('href', '/cart')
  })

  it('has a health link in navigation', () => {
    const healthLink = screen.getByRole('link', { name: /health/i })
    expect(healthLink).toHaveAttribute('href', '/health')
  })
})
