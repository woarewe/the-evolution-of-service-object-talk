ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Base.transaction do
  addresses = Array.new(20) do
    Address.create!(
      country: Faker::Address.country,
      state: Faker::Address.state,
      city: Faker::Address.city,
      zip: Faker::Address.zip,
      street: Faker::Address.street_address,
      street2: Faker::Address.street_address
    )
  end

  products = Array.new(10) do
    Product.create!(
      title: Faker::Lorem.unique.sentence,
      stock_quantity: 10,
      unit_price: rand(100)
    )
  end

  users = Array.new(10) do
    User.create!(
      username: Faker::Internet.username,
      auth_token: Faker::Internet.unique.uuid,
      email: Faker::Internet.unique.email,
      balance: rand(100)
    )
  end

  carts = Array.new(30) do
    Cart.create!(
      user: users.sample
    )
  end

  line_items = Array.new(20) do
    LineItem.create!(
      product: products.sample,
      cart: carts.sample,
      quantity: rand(3)
    )
  end

  orders = Array.new(10) do
    begin
      cart = carts.sample
      Order.create!(
        cart: cart,
        shipping_address: addresses.sample,
        user: cart.user,
        total: cart.line_items.sum { |item| item.product.unit_price * item.quantity },
        summary: "Summary"
      )
    rescue ActiveRecord::RecordNotUnique
      retry
    end
  end
end
