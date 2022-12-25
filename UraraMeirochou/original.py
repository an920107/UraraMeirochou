import matplotlib.pyplot as plt
import numpy as np
import pylab as pl
import random
from matplotlib import collections  as mc
import os

def drawline(p1, p2):
    x, y = [p1[0], p2[0]], [p1[1], p2[1]]
    plt.plot(x, y)

class DSU:
    def __init__(self, N):
        self.root = [i for i in range(N)]
    
    def find(self, x):
        if self.root[x] == x:
            return x
        self.root[x] = self.find(self.root[x])
        return self.root[x]
    
    def union(self, x, y):
        x = self.find(x)
        y = self.find(y)
        if x != y:
            self.root[x] = y
            return True
        return False

# n, m = input().split()
# n = int(n)
# m = int(m)

while True:

    os.system("cls")
    while True:
        try:
            n = m = int(input("Enter the maze size (3 ~ 30): "))
            if (n < 3 or n > 30):
                raise
        except:
            os.system("cls")
            print("The size should be between 3 and 30.")
        else: break
    # n = m = m << 1

    def encode(x, y):
        global m
        return x * m + y

    def decode(x):
        global m
        return (x // m, x % m)

    edg = []

    for i in range(n):
        for j in range(m):
            if i + 1 < n:
                if j == 0 or j == m-1: continue
                edg.append((encode(i, j), encode(i + 1, j)))
            if j + 1 < m:
                if i == 0 or i == n-1: continue
                edg.append((encode(i, j), encode(i, j + 1)))

    random.shuffle(edg)

    for i in range(n):
        for j in range(m):
            if i == 0 or i == n - 1:
                if j == m-1: continue
                edg.append((encode(i, j), encode(i, j + 1)))
            if j == 0 or j == m - 1:
                if i == 0 and j == 0: continue
                if i == n-2 and j == m-1: continue
                if i == n-1: continue
                edg.append((encode(i, j), encode(i + 1, j)))

    edg.reverse()

    add = []

    dsu = DSU(n * m)

    for [x, y] in edg:
        if dsu.union(x, y):
            print(decode(x), decode(y))
            add.append((x, y))
    
    add.pop()

    file_out = open("map.txt", "w")
    file_out.write(f"{n}\n")

    for [x, y] in add:
        drawline(decode(x), decode(y))
        x_point, y_point = decode(x), decode(y)
        file_out.write(f"{x_point[0]},{x_point[1]},{y_point[0]},{y_point[1]}\n")

    file_out.write("~")
    file_out.close()

    plt.show()

    os.system("UraraMeirochou.exe")