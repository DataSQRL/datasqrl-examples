import os
import random
from datetime import datetime, timedelta

from faker import Faker
from faker.providers import DynamicProvider

from generate_routes import generate_vehicle_statuses
from serializer import jsonify

number_of_customers = 15
number_of_shipments = 50
number_of_zones = 3

customer_registration_window_start = '-7d'
customer_registration_window_end = '-6d'
purchase_window_start = '-6d'
purchase_window_end = '-5d'

faker = Faker(["en_US"])

faker.add_provider(DynamicProvider(
    provider_name="van_type",
    elements=["BOX_TRUCK", "HEAVY_TRUCK", "CARGO_VAN"]
))


def generate_customer(customer_id):
    return {
        "id": customer_id,
        "lastUpdated": faker.date_time_between(customer_registration_window_start, customer_registration_window_end),
        "email": faker.email(),
        "phone": faker.phone_number()
    }


def generate_shipments(vehicle_statuses, customer_count):
    shipments = []
    delivery_vehicles = []  # This is a little hack to spare some iterations downstream.
    for i in range(len(vehicle_statuses)):
        vehicle_status = vehicle_statuses[i]

        # Simulating estimated delivery time. It is +-30min around when the vehicle arrives.
        delivery_from = vehicle_status['timestamp'] - timedelta(seconds=1800)
        delivery_to = vehicle_status['timestamp'] + timedelta(seconds=1800)

        shipments.append({
            "id": i,
            "lastUpdated": faker.date_time_between(purchase_window_start, purchase_window_end),
            "origin": faker.country(),
            "lat": vehicle_status['lat'],
            "lon": vehicle_status['lon'],
            "weight": round(random.uniform(0.1, 10), 1),
            "estimatedDelivery": faker.date_time_between(delivery_from, delivery_to),
            "customerId": random.randint(0, customer_count - 1)
        })

        delivery_vehicles.append(vehicle_status['vehicleId'])

    return shipments, delivery_vehicles


def generate_vehicle(vehicle_id):
    return {
        "id": vehicle_id,
        "type": faker.van_type(),
        "capacity": random.randint(100, 500)
    }


def generate_shipment_location(timestamp, shipment_id, vehicle_id):
    return {
        "timestamp": timestamp,
        "shipmentId": shipment_id,
        "vehicleId": vehicle_id
    }


# We have {number_of_customers} customers.
customers = [generate_customer(i) for i in range(number_of_customers)]

# Simulating a route for vehicles, we generate {number_of_shipments} + 2 + {number_of_zones} events.
# For each zone there will be exactly 1 vehicle.
# 2 event for the vehicle '0' to simulate regional transport and
# {number_of_vehicles} when assigning the shipments to vehicles.
# The rest are the events when a vehicle reaches a destination.
# vehicle_statuses = generate_vehicle_statuses(number_of_zones, number_of_shipments, datetime.now())
vehicle_statuses = generate_vehicle_statuses(number_of_zones, number_of_shipments, datetime.now(), True, ['r', 'b', 'y', 'g'])

# For each destination generate a shipment. Remember, we need to skip the first n elements.
# The customers are placing their orders for a day.
n = number_of_zones + 2
shipments, delivery_vehicles = generate_shipments(vehicle_statuses[n:], number_of_customers)

# We have {number_of_zones} + 1 vehicles. The + 1 is the one used for the regional route.
number_of_vehicles = number_of_zones + 1
vehicles = [generate_vehicle(i) for i in range(number_of_vehicles)]

# We assign each shipment to the '0' vehicle to simulate they arrive to the city.
shipment_locations = [generate_shipment_location(vehicle_statuses[0]['timestamp'], shipment['id'], 0) for shipment in shipments]

# Then we distribute them and assign each shipment to a vehicle ensuring that
# the vehicle is on a path that aligns with the shipment destination.
for i in range(len(shipments)):
    # vehicle_statuses[2..4] have the same timestamp ast these are the initial events for each route.
    shipment_locations.append(generate_shipment_location(vehicle_statuses[2]['timestamp'], shipments[i]['id'], delivery_vehicles[i]))

# Ensure that shipment_location events are ordered by their timestamp
shipment_locations.sort(key=lambda x: x["timestamp"])

# Ensure that vehicle_status events are ordered by their timestamp
vehicle_statuses.sort(key=lambda x: x["timestamp"])

# Dump the generated data
root_db_directory = "datagen/generated/db"
root_stream_directory = "datagen/generated/stream"
os.makedirs(root_db_directory)
os.makedirs(root_stream_directory)

with open(root_db_directory + "/customer.json", "w") as file:
    [file.writelines(jsonify(i) + '\n') for i in customers]

with open(root_db_directory + "/shipment.json", "w") as file:
    [file.writelines(jsonify(i) + '\n') for i in shipments]

with open(root_db_directory + "/vehicle.json", "w") as file:
    [file.writelines(jsonify(i) + '\n') for i in vehicles]

with open(root_stream_directory + "/shipment_location.json", "w") as file:
    [file.writelines(jsonify(i) + '\n') for i in shipment_locations]

with open(root_stream_directory + "/vehicle_status.json", "w") as file:
    [file.writelines(jsonify(i) + '\n') for i in vehicle_statuses]
