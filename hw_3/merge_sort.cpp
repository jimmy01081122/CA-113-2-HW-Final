#include <fcntl.h>
#include <unistd.h>
#include <cstring>
#include <cstdio>
#include <cstdlib>

const int MAX_SENTINEL = 1000000000;
#define MAX_SIZE 128

void writeOutput(const char* str) {
    write(STDOUT_FILENO, str, strlen(str));
}

void writeInt(int num) {
    char buffer[32];
    int len = snprintf(buffer, sizeof(buffer), "%d ", num);
    write(STDOUT_FILENO, buffer, len);
}

// 簡易線性同餘生成器 (LCG) 以替代 rand()
unsigned int simpleRand(unsigned int& seed) {
    seed = (1103515245 * seed + 12345) & 0x7fffffff;
    return seed % 1000;
}

void Merge(int arr[], int front, int mid, int end) {
    int leftSize = mid - front + 1;
    int rightSize = end - mid;

    int* leftSub = new int[leftSize + 1];
    int* rightSub = new int[rightSize + 1];

    for (int i = 0; i < leftSize; i++)
        leftSub[i] = arr[front + i];
    for (int j = 0; j < rightSize; j++)
        rightSub[j] = arr[mid + 1 + j];

    leftSub[leftSize] = MAX_SENTINEL;
    rightSub[rightSize] = MAX_SENTINEL;

    int idxLeft = 0, idxRight = 0;
    for (int k = front; k <= end; k++) {
        if (leftSub[idxLeft] <= rightSub[idxRight])
            arr[k] = leftSub[idxLeft++];
        else
            arr[k] = rightSub[idxRight++];
    }

    delete[] leftSub;
    delete[] rightSub;
}

void MergeSort(int arr[], int front, int end) {
    if (front < end) {
        int mid = (front + end) >> 1;
        MergeSort(arr, front, mid);
        MergeSort(arr, mid + 1, end);
        Merge(arr, front, mid, end);
    }
}

void initializeArray(int arr[], int size) {
    unsigned int seed = 1;  // 使用固定種子以避免不支援的 time() syscall
    for (int i = 0; i < size; i++)
        arr[i] = simpleRand(seed);
}

void PrintArray(const int arr[], int size) {
    for (int i = 0; i < size; i++)
        writeInt(arr[i]);
    writeOutput("\n");
}

int main() {
    int arr[MAX_SIZE] = {0};
    initializeArray(arr, MAX_SIZE);

    writeOutput("Original array:\n");
    PrintArray(arr, MAX_SIZE);

    MergeSort(arr, 0, MAX_SIZE - 1);

    writeOutput("\nSorted array:\n");
    PrintArray(arr, MAX_SIZE);

    char buffer[64];
    int len = snprintf(buffer, sizeof(buffer), "\nSorted numbers: %d\n", MAX_SIZE);
    write(STDOUT_FILENO, buffer, len);

    return 0;
}