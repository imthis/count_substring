#include <iostream>
#include <fstream>
#include <unordered_map>
#include <string>
#include <cmath>
#include <chrono>

const int PRIME = 37;  
const int MOD = 1e9 + 7;  

// calculating hash for a substring
int calculateHash(const std::string& str) {
    int hashValue = 0;
    int power = 1;

    for (char c : str) {
        hashValue = (hashValue + (c - 'a' + 1) * power) % MOD;
        power = (power * PRIME) % MOD;
    }

    return hashValue;
}

// counting substring frequencies using hash
void countSubstringFrequencies(const std::string& filename, std::unordered_map<int, int>& substringCount, int maxSubstringLength) {
    std::ifstream file(filename);
    
    if (!file.is_open()) {
        std::cerr << "Error opening file!" << std::endl;
        return;
    }

    std::string line;
    std::string content;

    while (getline(file, line)) {
        content += line + " ";  // changing multiple lines of text into a single string
    }

    for (size_t i = 0; i < content.length(); ++i) {
        int hashValue = 0;
        int power = 1;

        for (size_t j = i; j < content.length() && j < i + maxSubstringLength; ++j) {
            // updating hash value for the current substring
            hashValue = (hashValue + (content[j] - 'a' + 1) * power) % MOD;
            power = (power * PRIME) % MOD;

            // counting the occurrence of this substring hash
            substringCount[hashValue]++;
        }
    }

    file.close();
}

// searching for a substring frequency
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
    // text file path
    std::string filename = "/count.txt";
    auto start_time = std::chrono::high_resolution_clock::now();

    std::unordered_map<int, int> substringCount;

    // maximum length of substring to be searched
    int maxSubstringLength = 500;

    // fucntion call for counting substring occurrence
    countSubstringFrequencies(filename, substringCount, maxSubstringLength);

    std::string searchTerm = "ie"; // string to be searched

    searchSubstringFrequency(substringCount, searchTerm);
    auto end_time = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> duration = end_time - start_time;
    std::cout << "Simulation completed in " << duration.count() << " seconds." << std::endl;

    return 0;
}
