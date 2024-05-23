import random
import osmnx as ox
import os
from scipy.spatial import distance_matrix
from tsp_solver.greedy import solve_tsp
import networkx as nx


def create_or_load_map(graph_area, file_path):
    if os.path.exists(file_path):
        return ox.load_graphml(file_path)
    else:
        # Create the graph of the area from OSM data. It will download the data and create the graph
        graph = ox.graph_from_place(graph_area, network_type='drive')

        # OSM data are sometime incomplete so we use the speed module of osmnx to add missing edge speeds and travel times
        graph = ox.add_edge_speeds(graph)
        graph = ox.add_edge_travel_times(graph)

        # Save graph to disk to reuse it
        ox.save_graphml(graph, file_path)

        return graph


def get_boundaries(y_max, y_min, zone_count):
    zone_height = (y_max - y_min) / zone_count
    return [(round(y_min + i * zone_height, 4), round(y_min + (i + 1) * zone_height, 4)) for i in range(zone_count)]


def get_boundary(y, boundaries):
    for i in range(len(boundaries)):
        if boundaries[i][0] < y < boundaries[i][1]:
            return i


def generate_random_destinations(graph, count, boundaries):
    destinations = [[] for _ in boundaries]

    for _ in range(count):
        # Select a random node from the graph. This way we can ensure that the extracted coordinate is within the graph.
        random_node = graph.nodes[random.choice(list(graph.nodes()))]
        y = random_node['y']
        x = random_node['x']
        destinations[get_boundary(y, boundaries)].append((y, x))

    return destinations


def optimize_route(destinations):
    # Compute the distance matrix between destinations
    dist_matrix = distance_matrix(destinations, destinations)

    # Solve the TSP to find the optimal route
    route_indices = solve_tsp(dist_matrix)

    # Reorder the destinations based on the optimal route
    return [destinations[i] for i in reversed(route_indices)]


def create_route_between_coordinates(graph, origin, destination):
    # In the graph, get the nodes closest to the points
    origin_node = ox.nearest_nodes(graph, Y=origin[0], X=origin[1])
    destination_node = ox.nearest_nodes(graph, Y=destination[0], X=destination[1])
    # Get the shortest route by distance

    travel_time_in_seconds = nx.shortest_path_length(graph, origin_node, destination_node, weight='length')
    route = ox.shortest_path(graph, origin_node, destination_node, weight='length')
    return route, travel_time_in_seconds
