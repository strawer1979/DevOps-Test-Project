import { Link } from 'react-router-dom'

function ProductCard({ product }) {
  return (
    <div className="product-card">
      <Link to={`/products/${product.id}`} className="product-card-link">
        <div className="product-card-image">
          {product.image ? (
            <img src={product.image} alt={product.name} />
          ) : (
            <div className="placeholder-image">No Image</div>
          )}
        </div>
        <div className="product-card-content">
          <h3 className="product-card-title">{product.name}</h3>
          <p className="product-card-category">{product.category}</p>
          <p className="product-card-price">${product.price?.toFixed(2)}</p>
        </div>
      </Link>
    </div>
  )
}

export default ProductCard
