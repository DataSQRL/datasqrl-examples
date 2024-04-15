import os
from datetime import timedelta

import imageio.v2 as imageio
import osmnx as ox

from utils import generate_random_destinations, create_or_load_map, optimize_route, create_route_between_coordinates, \
    get_boundaries


def generate_vehicle_statuses(number_of_zones, number_of_destinations, start_time, create_gif=False, colors=None):
    # You need as many color as many zones (routes) you have + 1 for the regional route.
    # The first is the regional route's color.
    if create_gif and (colors is None or len(colors) != number_of_zones + 1):
        raise ValueError("If create_gif is True, colors must be provided and its length should be number_of_zones + 1.")

    G = create_or_load_map("Manhattan, New York, USA", "Manhattan.graphml")

    vehicle_statuses = []

    # These values are manually read from the map and used to
    # divide the map to equal slices on the y axis to generate zones.
    most_north_y = 40.8707
    most_south_y = 40.7021

    boundaries = get_boundaries(most_north_y, most_south_y, number_of_zones)

    # Create a route from George Washington Bridge to a local warehouse simulate regional transport between warehouses
    regional_route_from = (40.8497, -73.9430)
    regional_route_to = (40.7883, -73.9787)

    current_time = start_time
    vehicle_statuses.append({
        "timestamp": current_time,
        "lat": regional_route_from[0],
        "lon": regional_route_from[1],
        "vehicleId": 0
    })

    route, travel_time = create_route_between_coordinates(G, regional_route_from, regional_route_to)

    current_time += timedelta(seconds=travel_time)
    vehicle_statuses.append({
        "timestamp": current_time,
        "lat": regional_route_to[0],
        "lon": regional_route_to[1],
        "vehicleId": 0,
        "route": route
    })

    # Create destinations grouped into zones like this [[(y, x), (y, x)], [(y, x), (y, x)], ..., [(y, x), (y, x)]]
    destinations = generate_random_destinations(G, number_of_destinations, boundaries)

    # Cargo vans are leaving an hour after the truck arrived at the warehouse.
    distribution_start_time = current_time + timedelta(seconds=3600)

    # Create a route for each zone to simulate vehicle routes for distribution.
    for zone_id in range(number_of_zones):
        # In each zone there's exactly one (for now) delivery vehicle. 0 is reserved for the regional route.
        vehicle_id = zone_id + 1

        # Append regional route's destination, so it will be the origin of the local route.
        destinations[zone_id].append(regional_route_to)

        # We need to add an event manually here as in the next section we generate an event when the
        # vehicle arrives to a destination. That's why there's no route here as we are just specifying
        # the new starting point here.
        current_time = distribution_start_time
        vehicle_statuses.append({
            "timestamp": current_time,
            "lat": regional_route_to[0],
            "lon": regional_route_to[1],
            "vehicleId": vehicle_id
        })

        # With OSMnx it is not possible to create a route based on multiple destinations. So here I'm taking another
        # approach to optimize the "route". The output of this method is an ordered list (based on shortest route) that
        # we can use in OSMnx to draw the actual routes between two points.
        optimal_route = optimize_route(destinations[zone_id])

        for route_id in range(len(optimal_route) - 1):
            current_origin = optimal_route[route_id]
            current_destination = optimal_route[route_id + 1]

            route, travel_time = create_route_between_coordinates(G, current_origin, current_destination)

            current_time += timedelta(seconds=travel_time)
            vehicle_statuses.append({
                "timestamp": current_time,
                "lat": current_destination[0],
                "lon": current_destination[1],
                "vehicleId": vehicle_id,
                "route": route
            })

    vehicle_statuses.sort(key=lambda x: x["timestamp"])

    if create_gif:
        generate_gif(G, vehicle_statuses, colors)

    # Remove the "route" field vehicle_status as it is not needed upstream
    for vehicle_status in vehicle_statuses:
        if "route" in vehicle_status:
            del vehicle_status["route"]

    return vehicle_statuses


def generate_gif(graph, vehicle_statuses, colors):
    routes = []
    route_colors = []
    images = []

    directory = "datagen/generated/assets/"
    os.makedirs(directory)

    for vehicle_status in vehicle_statuses:
        if "route" in vehicle_status:
            routes.append(vehicle_status['route'])
            route_colors.append(colors[vehicle_status['vehicleId']])

            path = directory + str(vehicle_status['timestamp']) + ".png"
            if len(routes) == 1:
                ox.plot_graph_route(graph, routes[0], route_colors[0], show=False, save=True, filepath=path,
                                    route_linewidth=1, orig_dest_size=50, node_size=0)
            else:
                ox.plot_graph_routes(graph, routes, route_colors, show=False, save=True, filepath=path,
                                     route_linewidth=1, orig_dest_size=50, node_size=0)

            images.append(imageio.imread(path))

    imageio.mimsave(directory + "logistics.gif", images, duration=1)
    print("Created gif successfully.")

# You can just generate a set of routes by running this file
# and uncommenting this line with `python generate_routes.py`:
# generate_vehicle_statuses(3, 50, datetime.now(), True, ['r', 'b', 'y', 'g'])
