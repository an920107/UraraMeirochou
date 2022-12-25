import numpy
import pylab
import random
import os

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
    n = m = m << 1

    edg = []

    def encode(x, y):
        return x * m + y

    def decode(x):
        return (x // m, x % m)

    for i in range(n):
        for j in range(m):
            if i + 1 < n:
                if j == 0 or j == m-1: continue
                edg.append((encode(i, j), encode(i+1, j)))
            if j + 1 < m:
                if i == 0 or i == n-1: continue
                edg.append((encode(i, j), encode(i, j+1)))

    random.shuffle(edg)

    for j in range(m-1):
        edg.append((encode(0, j), encode(0, j+1)))
        edg.append((encode(n-1, j), encode(n-1, j+1)))

    for i in range(n-1):
        if i != 0: edg.append((encode(i, 0), encode(i+1, 0)))
        if i != n-2: edg.append((encode(i, m-1), encode(i+1, m-1)))
    edg.reverse()

    add = []

    dsu = DSU(n * m)
    for [x, y] in edg:
        a, b = dsu.find(encode(0, 0)), dsu.find(encode(n-1, m-1))
        c, d = dsu.find(x), dsu.find(y)
        if a > b: a, b = b, a
        if c > d: c, d = d, c
        if (a, b) == (c, d): continue
        if dsu.union(x, y):
            add.append((x, y))

    file_out = open("map.txt", "w")
    file_out.write(f"{n}\n")

    for [x, y] in add:
        x_point, y_point = decode(x), decode(y)
        file_out.write(f"{x_point[0]},{x_point[1]},{y_point[0]},{y_point[1]}\n")
    file_out.write("0,0,1,0\n")

    file_out.write("~")
    file_out.close()

    os.system("UraraMeirochou.exe")