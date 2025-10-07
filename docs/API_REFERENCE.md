# Medusa Backend API Reference

Quick reference for accessing the Medusa backend APIs and admin dashboard.

## Table of Contents
- [Base URLs](#base-urls)
- [Authentication](#authentication)
- [Store API](#store-api)
- [Admin API](#admin-api)
- [Health & Status](#health--status)
- [Common Workflows](#common-workflows)

---

## Base URLs

### Current Deployment
- **Internal (VM):** `http://localhost:9000`
- **External:** `http://34.28.27.211:9000` (update with your actual IP)
- **Production (with SSL):** `https://api.yourdomain.com`

### Endpoints
- **Health Check:** `/health`
- **Store API:** `/store/*`
- **Admin API:** `/admin/*`
- **Admin Dashboard:** `/app`

---

## Authentication

### Admin Authentication

#### Login
```bash
POST /admin/auth/session
Content-Type: application/json

{
  "email": "admin@medusa.com",
  "password": "supersecret123"
}
```

**Response:**
```json
{
  "user": {
    "id": "usr_...",
    "email": "admin@medusa.com",
    "first_name": null,
    "last_name": null
  }
}
```

**Cookie:** Session cookie is automatically set

#### Get Current User
```bash
GET /admin/auth/session
Cookie: connect.sid=...
```

#### Logout
```bash
DELETE /admin/auth/session
Cookie: connect.sid=...
```

### Store Authentication (Customer)

#### Register Customer
```bash
POST /store/auth/customer/emailpass/register
Content-Type: application/json

{
  "email": "customer@example.com",
  "password": "password123"
}
```

#### Login Customer
```bash
POST /store/auth/customer/emailpass
Content-Type: application/json

{
  "email": "customer@example.com",
  "password": "password123"
}
```

---

## Store API

The Store API is used by storefronts to browse products, manage carts, and place orders.

### Products

#### List Products
```bash
GET /store/products
```

**Query Parameters:**
- `q`: Search query
- `limit`: Results per page (default: 50)
- `offset`: Pagination offset
- `category_id[]`: Filter by category IDs
- `collection_id[]`: Filter by collection IDs
- `region_id`: Filter by region

**Example:**
```bash
curl http://localhost:9000/store/products?limit=10
```

#### Get Product
```bash
GET /store/products/:id
```

**Example:**
```bash
curl http://localhost:9000/store/products/prod_123
```

### Regions

#### List Regions
```bash
GET /store/regions
```

#### Get Region
```bash
GET /store/regions/:id
```

### Cart

#### Create Cart
```bash
POST /store/carts
Content-Type: application/json

{
  "region_id": "reg_123",
  "items": [
    {
      "variant_id": "variant_123",
      "quantity": 1
    }
  ]
}
```

#### Get Cart
```bash
GET /store/carts/:id
```

#### Add Line Item
```bash
POST /store/carts/:id/line-items
Content-Type: application/json

{
  "variant_id": "variant_123",
  "quantity": 2
}
```

#### Update Line Item
```bash
POST /store/carts/:id/line-items/:line_id
Content-Type: application/json

{
  "quantity": 3
}
```

#### Delete Line Item
```bash
DELETE /store/carts/:id/line-items/:line_id
```

#### Complete Cart (Create Order)
```bash
POST /store/carts/:id/complete
```

### Orders

#### Get Order
```bash
GET /store/orders/:id
```

**Requires:** Customer authentication or order token

---

## Admin API

The Admin API is used to manage products, orders, customers, and settings.

### Products

#### List Products
```bash
GET /admin/products
Cookie: connect.sid=...
```

**Query Parameters:**
- `q`: Search query
- `limit`: Results per page
- `offset`: Pagination offset
- `status[]`: Filter by status (draft, proposed, published, rejected)

#### Create Product
```bash
POST /admin/products
Cookie: connect.sid=...
Content-Type: application/json

{
  "title": "Product Name",
  "description": "Product description",
  "status": "published",
  "variants": [
    {
      "title": "Default Variant",
      "prices": [
        {
          "amount": 1000,
          "currency_code": "usd"
        }
      ]
    }
  ]
}
```

#### Update Product
```bash
POST /admin/products/:id
Cookie: connect.sid=...
Content-Type: application/json

{
  "title": "Updated Product Name"
}
```

#### Delete Product
```bash
DELETE /admin/products/:id
Cookie: connect.sid=...
```

### Orders

#### List Orders
```bash
GET /admin/orders
Cookie: connect.sid=...
```

#### Get Order
```bash
GET /admin/orders/:id
Cookie: connect.sid=...
```

#### Update Order
```bash
POST /admin/orders/:id
Cookie: connect.sid=...
Content-Type: application/json

{
  "email": "newemail@example.com"
}
```

#### Capture Payment
```bash
POST /admin/orders/:id/capture
Cookie: connect.sid=...
```

#### Create Fulfillment
```bash
POST /admin/orders/:id/fulfillment
Cookie: connect.sid=...
Content-Type: application/json

{
  "items": [
    {
      "item_id": "item_123",
      "quantity": 1
    }
  ]
}
```

### Customers

#### List Customers
```bash
GET /admin/customers
Cookie: connect.sid=...
```

#### Get Customer
```bash
GET /admin/customers/:id
Cookie: connect.sid=...
```

#### Create Customer
```bash
POST /admin/customers
Cookie: connect.sid=...
Content-Type: application/json

{
  "email": "customer@example.com",
  "first_name": "John",
  "last_name": "Doe"
}
```

### Collections

#### List Collections
```bash
GET /admin/collections
Cookie: connect.sid=...
```

#### Create Collection
```bash
POST /admin/collections
Cookie: connect.sid=...
Content-Type: application/json

{
  "title": "Summer Collection",
  "handle": "summer-collection"
}
```

### Regions

#### List Regions
```bash
GET /admin/regions
Cookie: connect.sid=...
```

#### Create Region
```bash
POST /admin/regions
Cookie: connect.sid=...
Content-Type: application/json

{
  "name": "United States",
  "currency_code": "usd",
  "countries": ["us"],
  "payment_providers": ["manual"],
  "fulfillment_providers": ["manual"]
}
```

---

## Health & Status

### Health Check
```bash
GET /health
```

**Response:**
```
OK
```

**Use Case:** Load balancer health checks, monitoring

### PM2 Status (SSH)
```bash
pm2 status
```

### View Logs
```bash
# All logs
pm2 logs

# Backend only
pm2 logs medusa-backend

# Worker only
pm2 logs medusa-worker

# Last 50 lines
pm2 logs --lines 50
```

---

## Common Workflows

### 1. Create Complete Product

```bash
# Login as admin
curl -X POST http://localhost:9000/admin/auth/session \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@medusa.com",
    "password": "supersecret123"
  }' \
  -c cookies.txt

# Create product
curl -X POST http://localhost:9000/admin/products \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{
    "title": "Cool T-Shirt",
    "description": "A very cool t-shirt",
    "status": "published",
    "variants": [
      {
        "title": "Small",
        "prices": [
          {
            "amount": 1999,
            "currency_code": "usd"
          }
        ],
        "options": [
          {
            "value": "S"
          }
        ]
      },
      {
        "title": "Medium",
        "prices": [
          {
            "amount": 1999,
            "currency_code": "usd"
          }
        ],
        "options": [
          {
            "value": "M"
          }
        ]
      }
    ]
  }'
```

### 2. Complete Checkout Flow

```bash
# 1. Create cart
CART=$(curl -X POST http://localhost:9000/store/carts \
  -H "Content-Type: application/json" \
  -d '{
    "region_id": "reg_01...",
    "items": [
      {
        "variant_id": "variant_01...",
        "quantity": 1
      }
    ]
  }' | jq -r '.cart.id')

# 2. Add shipping address
curl -X POST "http://localhost:9000/store/carts/$CART" \
  -H "Content-Type: application/json" \
  -d '{
    "shipping_address": {
      "first_name": "John",
      "last_name": "Doe",
      "address_1": "123 Main St",
      "city": "New York",
      "country_code": "us",
      "postal_code": "10001"
    }
  }'

# 3. Add shipping method
curl -X POST "http://localhost:9000/store/carts/$CART/shipping-methods" \
  -H "Content-Type: application/json" \
  -d '{
    "option_id": "so_01..."
  }'

# 4. Complete cart
curl -X POST "http://localhost:9000/store/carts/$CART/complete"
```

### 3. Search Products

```bash
# Search by title
curl "http://localhost:9000/store/products?q=shirt"

# Filter by category
curl "http://localhost:9000/store/products?category_id[]=cat_01..."

# Pagination
curl "http://localhost:9000/store/products?limit=10&offset=0"
```

### 4. Customer Registration & Order

```bash
# 1. Register customer
curl -X POST http://localhost:9000/store/auth/customer/emailpass/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "customer@example.com",
    "password": "secure-password"
  }' \
  -c customer-cookies.txt

# 2. Browse products (authenticated)
curl http://localhost:9000/store/products \
  -b customer-cookies.txt

# 3. Create cart and checkout (same as above, with cookies)
```

---

## Admin Dashboard

### Access
```
http://34.28.27.211:9000/app
```

**Login Credentials:**
- Email: `admin@medusa.com`
- Password: `supersecret123`

### Dashboard Features
- **Products:** Create, edit, delete products and variants
- **Orders:** View and manage orders, fulfillments, payments
- **Customers:** Manage customer accounts
- **Discounts:** Create discount codes and promotions
- **Settings:** Configure regions, currencies, shipping, payments
- **Analytics:** View sales data and metrics (if configured)

---

## API Response Formats

### Success Response
```json
{
  "product": {
    "id": "prod_01...",
    "title": "Product Name",
    ...
  }
}
```

### Error Response
```json
{
  "type": "invalid_data",
  "message": "The product title is required"
}
```

### List Response
```json
{
  "products": [...],
  "count": 100,
  "offset": 0,
  "limit": 50
}
```

---

## Rate Limiting

Currently no rate limiting is configured. For production, consider:

1. **nginx rate limiting** (if using reverse proxy)
2. **Application-level rate limiting** (express-rate-limit)
3. **GCP Cloud Armor** (if using Load Balancer)

Example nginx rate limit:
```nginx
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

location / {
    limit_req zone=api burst=20 nodelay;
    proxy_pass http://localhost:9000;
}
```

---

## CORS Configuration

### Current Settings
```
STORE_CORS=http://localhost:8000,https://your-storefront.run.app
ADMIN_CORS=http://localhost:9000,http://34.28.27.211:9000
```

### Update CORS
1. Edit `.env`:
   ```bash
   nano ~/medusa-app/.env
   ```

2. Add allowed origins:
   ```
   STORE_CORS=https://shop.yourdomain.com,https://staging.yourdomain.com
   ADMIN_CORS=https://admin.yourdomain.com
   ```

3. Restart:
   ```bash
   pm2 restart all
   ```

---

## Webhooks

### Configure Webhooks (Admin Dashboard)
1. Navigate to Settings > Webhooks
2. Click "Create Webhook"
3. Enter URL and select events
4. Save

### Webhook Events
- `order.placed`
- `order.updated`
- `order.canceled`
- `customer.created`
- `product.created`
- `product.updated`
- Many more...

### Example Webhook Handler
```javascript
app.post('/webhooks/medusa', (req, res) => {
  const event = req.body;

  switch(event.event) {
    case 'order.placed':
      console.log('New order:', event.data.id);
      // Send confirmation email
      break;
    case 'product.created':
      console.log('New product:', event.data.id);
      // Update search index
      break;
  }

  res.sendStatus(200);
});
```

---

## Testing with cURL

### Set Variables
```bash
export BACKEND_URL="http://localhost:9000"
export ADMIN_EMAIL="admin@medusa.com"
export ADMIN_PASSWORD="supersecret123"
```

### Admin Login
```bash
curl -X POST $BACKEND_URL/admin/auth/session \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$ADMIN_EMAIL\",
    \"password\": \"$ADMIN_PASSWORD\"
  }" \
  -c cookies.txt -v
```

### Make Authenticated Request
```bash
curl $BACKEND_URL/admin/products \
  -b cookies.txt
```

---

## Integration Examples

### JavaScript/TypeScript
```typescript
import Medusa from "@medusajs/medusa-js"

const medusa = new Medusa({
  baseUrl: "http://localhost:9000",
  maxRetries: 3
})

// List products
const { products } = await medusa.products.list()

// Admin login
const { user } = await medusa.admin.auth.createSession({
  email: "admin@medusa.com",
  password: "supersecret123"
})

// Create product (as admin)
const { product } = await medusa.admin.products.create({
  title: "New Product",
  status: "published"
})
```

### Python
```python
import requests

BASE_URL = "http://localhost:9000"

# Login
session = requests.Session()
login_response = session.post(
    f"{BASE_URL}/admin/auth/session",
    json={
        "email": "admin@medusa.com",
        "password": "supersecret123"
    }
)

# List products
products_response = session.get(f"{BASE_URL}/admin/products")
products = products_response.json()
```

---

## Monitoring & Observability

### Health Check Endpoint
```bash
# Simple check
curl http://localhost:9000/health

# With timeout
curl --max-time 5 http://localhost:9000/health

# Check from monitoring service
*/5 * * * * curl -f http://localhost:9000/health || alert-team
```

### Logs
```bash
# Stream logs
pm2 logs --lines 100

# Search logs
pm2 logs | grep -i error

# Export logs
pm2 logs --nostream --lines 1000 > medusa-logs.txt
```

---

## Security Best Practices

1. **Always use HTTPS in production**
2. **Rotate secrets regularly**
3. **Implement rate limiting**
4. **Validate webhook signatures**
5. **Use environment-specific CORS settings**
6. **Enable audit logs**
7. **Implement proper authentication**
8. **Keep Medusa and dependencies updated**

---

## Additional Resources

- **Medusa API Reference:** https://docs.medusajs.com/api/store
- **Admin API Reference:** https://docs.medusajs.com/api/admin
- **JS Client:** https://docs.medusajs.com/js-client/overview
- **React Hooks:** https://docs.medusajs.com/ui/overview

---

*Last Updated: October 7, 2025*
