#include <iostream>
#include <fstream>
#include <unordered_map>
#include <string>
#include <cmath>
#include <chrono>
#include <cuda_runtime.h>

const int PRIME = 37;
const int MOD = 1e9 + 7;
// cuda kernel for counting substrings using hash
__global__ void countSubstringsKernel(const char* content, int* substringCount, int contentLength, int maxSubstringLength) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= contentLength) return;
    // printf("Block ID: %d, Block Dim: %d, Thread ID: %d\n", blockIdx.x, blockDim.x, threadIdx.x);
    // std::cout<<blockIdx.x<<"and"<<blockDim.x<<"and"<<threadIdx.x;


    for (int len = 1; len <= maxSubstringLength; ++len) {
        int hashValue = 0;
        int power = 1;
        // compute the hash for the current substring
        for (int j = i; j < i + len && j < contentLength; ++j) {
            hashValue = (hashValue + (content[j] - 'a' + 1) * power) % MOD;
            power = (power * PRIME) % MOD;

        }

        // atomically increment the hash count
        atomicAdd(&substringCount[hashValue], 1);
    }
}

std::string readFile(const std::string& filename) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Error opening file!" << std::endl;
        return "0";
    }
    std::string line, content;

    while (getline(file, line)) {
        content += line + " "; // changing multiple lines of text into a single string
    }

    return content;
}

// counting substring frequencies
void countSubstringFrequencies(const std::string& filename, std::unordered_map<int, int>& substringCount, int maxSubstringLength) {
    std::string content = readFile(filename);
    int contentLength = content.length();

    // device memory_allocation
    char* d_content;
    int* d_substringCount;

    cudaMalloc(&d_content, contentLength * sizeof(char));
    cudaMalloc(&d_substringCount, MOD * sizeof(int));
    // std::cout<<content.c_str();

    cudaMemcpy(d_content, content.c_str(), contentLength * sizeof(char), cudaMemcpyHostToDevice);
    cudaMemset(d_substringCount, 0, MOD * sizeof(int));
    char* h_content = new char[contentLength];

    // defining block size
    int blockSize = 1024;
    int gridSize = (contentLength + blockSize - 1) / blockSize;

    // launching cuda kernel
    countSubstringsKernel<<<gridSize, blockSize>>>(d_content, d_substringCount, contentLength, maxSubstringLength);

    cudaDeviceSynchronize();

    // back to host
    int* h_substringCount = new int[MOD];
    cudaMemcpy(h_substringCount, d_substringCount, MOD * sizeof(int), cudaMemcpyDeviceToHost);

    for (int i = 0; i < MOD; ++i) {
        if (h_substringCount[i] > 0) {
            substringCount[i] = h_substringCount[i];
        }
    }

    delete[] h_substringCount;
    cudaFree(d_content);
    cudaFree(d_substringCount);
}

// calculating hash for a substring
int calculateHash(const std::string& str) {
    int hashValue = 0;
    int power = 1;

    for (char c : str) {
        hashValue = (hashValue  + (c - 'a' + 1) * power) % MOD;
        power = (power * PRIME) % MOD;
    }

    return hashValue;
}

// searching substring frequency
void searchSubstringFrequency(const std::unordered_map<int, int>& substringCount, const std::string& substring) {
    int hashValue = calculateHash(substring);
    auto it = substringCount.find(hashValue);
    if (it != substringCount.end()) {
        std::cout << "Frequency of '" << substring << "': " << it->second << std::endl;
    } else {
        std::cout << "Substring not found." << std::endl;
    }
}

int main() {
    // txt file path
    std::string filename = "/mnt/c/Users/abhis/Desktop/RocketGPT/Dataset_files/manual/count.txt";
    auto start_time = std::chrono::high_resolution_clock::now();

    std::unordered_map<int, int> substringCount;

    // maximum length of substring
    int maxSubstringLength = 500;


    // counting all substrings possible
    countSubstringFrequencies(filename, substringCount, maxSubstringLength);
    
    std::string searchTerm = "aerot"; // substring to be serached

    searchSubstringFrequency(substringCount, searchTerm);

    auto end_time = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> duration = end_time - start_time;
    std::cout << "Simulation completed in " << duration.count() << " seconds." << std::endl;

    return 0;
}