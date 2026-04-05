import random
from faker import Faker
from datetime import datetime, timedelta

fake = Faker()

# =============================
# CONFIG – OPTION B
# =============================

NUM_CUSTOMERS = 1200
NUM_CATEGORIES = 15
NUM_PRODUCTS = 250
NUM_ORDERS = 8000
NUM_REVIEWS = 5000

output_file = open("insert_data.sql", "w", encoding="utf-8")

def write(line):
    output_file.write(line + "\n")

# =============================
# CUSTOMERS
# =============================

write("-- INSERT CUSTOMERS")

for i in range(NUM_CUSTOMERS):
    name = fake.name().replace("'", "")
    email = fake.unique.email()
    signup = fake.date_between(start_date="-2y", end_date="today")
    dob = fake.date_between(start_date="-40y", end_date="-18y")
    city = fake.city().replace("'", "")
    status = random.choices(
        ["active", "inactive", "banned"],
        weights=[0.78, 0.15, 0.07]
    )[0]

    write(f"""INSERT INTO customers 
(full_name,email,signup_date,date_of_birth,city,status)
VALUES ('{name}','{email}','{signup}','{dob}','{city}','{status}');""")

# =============================
# CATEGORIES
# =============================

write("\n-- INSERT CATEGORIES")

for i in range(1, NUM_CATEGORIES + 1):
    write(f"INSERT INTO categories (category_name) VALUES ('Category_{i}');")

# =============================
# PRODUCTS
# =============================

write("\n-- INSERT PRODUCTS")

for i in range(NUM_PRODUCTS):
    name = fake.word().capitalize() + " Product"
    category_id = random.randint(1, NUM_CATEGORIES)
    price = round(random.uniform(10, 500), 2)
    cost = round(price * random.uniform(0.5, 0.9), 2)
    created = fake.date_between(start_date="-2y", end_date="today")
    is_active = random.choices([1,0], weights=[0.88,0.12])[0]

    write(f"""INSERT INTO products
(product_name,category_id,price,cost,created_at,is_active)
VALUES ('{name}',{category_id},{price},{cost},'{created}',{is_active});""")

# =============================
# ORDERS + ORDER ITEMS + PAYMENTS
# =============================

write("\n-- INSERT ORDERS")

order_item_id = 1

for i in range(NUM_ORDERS):

    customer_id = random.randint(1, NUM_CUSTOMERS)
    order_date = fake.date_time_between(start_date="-1y", end_date="now")
    status = random.choices(
        ["completed","cancelled","refunded"],
        weights=[0.87,0.08,0.05]
    )[0]

    shipping = round(random.uniform(2,20),2)
    total_amount = 0

    write(f"""INSERT INTO orders
(customer_id,order_date,status,shipping_fee,total_amount)
VALUES ({customer_id},'{order_date}','{status}',{shipping},0);""")

    order_id = i + 1

    num_items = random.randint(1,4)

    for _ in range(num_items):
        product_id = random.randint(1, NUM_PRODUCTS)
        quantity = random.randint(1,3)
        base_price = round(random.uniform(10,500),2)

        # 10% discount anomaly
        if random.random() < 0.1:
            unit_price = round(base_price * random.uniform(0.6,0.9),2)
        else:
            unit_price = base_price

        total_amount += quantity * unit_price

        write(f"""INSERT INTO order_items
(order_id,product_id,quantity,unit_price)
VALUES ({order_id},{product_id},{quantity},{unit_price});""")

    total_amount += shipping

    write(f"UPDATE orders SET total_amount={round(total_amount,2)} WHERE order_id={order_id};")

    # 7% orders without payment
    if random.random() > 0.07:

        paid_amount = total_amount

        # 6% mismatch anomaly
        if random.random() < 0.06:
            paid_amount = round(total_amount * random.uniform(0.7,1.2),2)

        payment_status = "paid"

        if status == "refunded":
            payment_status = "refunded"

        write(f"""INSERT INTO payments
(order_id,payment_method,payment_status,paid_amount,payment_date)
VALUES ({order_id},
'{random.choice(["card","ewallet","cod"])}',
'{payment_status}',
{round(paid_amount,2)},
'{order_date}');""")

# =============================
# REVIEWS
# =============================

write("\n-- INSERT REVIEWS")

for i in range(NUM_REVIEWS):
    product_id = random.randint(1, NUM_PRODUCTS)
    customer_id = random.randint(1, NUM_CUSTOMERS)
    rating = random.randint(1,5)
    review_date = fake.date_between(start_date="-1y", end_date="today")

    write(f"""INSERT INTO reviews
(product_id,customer_id,rating,review_date)
VALUES ({product_id},{customer_id},{rating},'{review_date}');""")

output_file.close()

print("Done. File insert_data.sql created.")