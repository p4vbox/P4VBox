#!/usr/bin/env python
import numpy as np

def main():
    times = []
    time = 0
    time = input("Input time:\n")
    while (time >= 0):
        times.append(time)
        time = input()

    # print(times)
    av = np.average(times)
    print("Average = "+ str(av)+ " ns")
    print("Average = "+ str(av/1000)+ " us")
    print("Average = "+ str(av/1000000)+ " ms")

if __name__ == "__main__":
    main()
