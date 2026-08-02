import { Link } from 'react-router-dom'

function Home() {
  return (
    <div className="home-page">
      <section className="hero">
        <h1>Welcome to ShopSimple</h1>
        <p>Your simple and easy e-commerce experience</p>
        <div className="hero-buttons">
          <Link to="/products" className="btn btn-primary">
            Browse Products
          </Link>
          <Link to="/cart" className="btn btn-secondary">
            View Cart
          </Link>
        </div>
      </section>
      <section className="features">
        <div className="feature">
          <h3>Easy Shopping</h3>
          <p>Browse our curated selection of products with ease</p>
        </div>
        <div className="feature">
          <h3>Secure Checkout</h3>
          <p>Your cart and checkout process is simple and secure</p>
        </div>
        <div className="feature">
          <h3>Fast Delivery</h3>
          <p>Get your orders delivered quickly to your doorstep</p>
        </div>
      </section>
    </div>
  )
}

export default Home
