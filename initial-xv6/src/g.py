import pandas as pd
import matplotlib.pyplot as plt

def read_process_data(filename):
    # Read the data, filtering out lines that don't start with 'GRAPH'
    with open(filename, 'r') as f:
        lines = f.readlines()

    data = []
    for line in lines:
        if line.startswith('GRAPH'):
            parts = line.strip().split()
            # Extract the PID, total ticks, queue, and state
            pid = parts[1]
            total_ticks = int(parts[2])
            queue = int(parts[3])
            data.append((pid, total_ticks, queue))

    return pd.DataFrame(data, columns=['pid', 'total_ticks', 'queue'])

def plot_process_queue(data):
    plt.figure(figsize=(12, 6))
    
    for pid, group in data.groupby('pid'):
        plt.plot(group['total_ticks'], group['queue'], label=f'PID {pid}', linewidth=2)

    plt.title('Process Queue Timeline')
    plt.xlabel('Time Elapsed (ticks)')
    plt.ylabel('Queue ID')
    plt.yticks(range(0, 4))  # Assuming queues are 0, 1, 2, 3
    plt.xticks(range(0, data['total_ticks'].max() + 1, 5))  # Adjust x-ticks as needed

    # Set the x-axis limit to show a higher range
    plt.xlim(0, data['total_ticks'].max() + 20)  # Increase the upper limit by 20 ticks

    plt.grid(True)
    plt.legend()
    plt.savefig('t1.png')

# Main execution
if __name__ == "__main__":
    filename = 't1.txt'  # Replace with your actual filename
    data = read_process_data(filename)
    plot_process_queue(data)
