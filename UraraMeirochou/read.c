#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main() {

    int index = 0;
    char buffer[10000];

    FILE *file = fopen("map.txt", "r");
    while (fscanf(file, "%c", &buffer[index ++]) != EOF);

    for (index = 0; index < strlen(buffer); index ++)
        printf("%d ", (int)buffer[index]);

    return 0;
}