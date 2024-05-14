#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LINE_LENGTH 256

int main(int argc, char* argv[]) {
  // Check for command line argument (filename)
  if (argc != 2) {
    printf("Usage: %s <filename>\n", argv[0]);
    return 1;
  }

  // Open the file for reading
  FILE* file = fopen(argv[1], "r");
  if (file == NULL) {
    perror("Error opening file");
    return 1;
  }

  // Allocate memory for a line buffer
  char line[MAX_LINE_LENGTH];
  char* token;
  float value;

  // Read lines from the file
  while (fgets(line, MAX_LINE_LENGTH, file)) {
    // Remove trailing newline character (if present)
    size_t len = strlen(line);
    if (line[len - 1] == '\n') {
      line[len - 1] = '\0';
    }

        // Get the first token (string)
    token = strtok(line, ";");  // strtok modifies the original string

    // Check if token exists (handle empty lines)
    if (token != NULL) {
      // Get the float value (convert string to float)
      value = strtof(strtok(NULL, ";"), NULL);  // strtok on the modified line

      // Process the data (replace with your logic)
      //printf("String: %s, Float Value: %f\n", token, value);
    }

    // Process the line (replace this with your desired processing)
    // printf("Line: %s\n", line);
  }

  // Close the file
  fclose(file);

  // Free memory (if dynamically allocated)
  // In this case, line buffer is declared on the stack, no need to free

  return 0;
}