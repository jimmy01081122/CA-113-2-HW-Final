// ONLY modify the implemntation of the LIS function !
// Compile hw2_ccode,cpp using "make hw2_compile_ccode"

#include <unistd.h>
#include <cstdio>

int LIS(int n, int* arr, int* dp) {
    // TODO: Implement your code here
    if (n <= 0) return 0;
    // initialize dp to 1
    for (int i = 0; i < n; ++i) {
        dp[i] = 1;
    }
    int max_len = 1;
    for (int i = 1; i < n; ++i) {
        for (int j = 0; j < i; ++j) {
            if (arr[j] < arr[i] && dp[j] + 1 > dp[i]) {
                dp[i] = dp[j] + 1;
            }
        }
        if (dp[i] > max_len) max_len = dp[i];
    }
    return max_len;
    //return -1;  // Return the length of the longest increasing subsequence
}

int main() {
    int arr[] = {34, 11, 91, 23, 46, 78, 98, 50, 54, 77, 27, 86, 91, 39, 95, 41, 57, 45, 55, 28, 68, 7, 85, 85, 48, 3, 93, 51, 11, 69, 78, 68, 51, 14, 18, 77, 6, 59, 35, 40, 18};  
    int n = sizeof(arr) / sizeof(arr[0]);
    int dp[n] = {0};  
    int result;

    result = LIS(n, arr, dp);
    
    char buffer[1024];
    int len = snprintf(buffer, sizeof(buffer), "Your answer = %d\n", result); // Gloden answer = 10
    
    if (len > 0) {
        write(STDOUT_FILENO, buffer, len);
    }
    
    return 0;
}
