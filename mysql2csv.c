#define _POSIX_C_SOURCE 200809L // For popen, pclose, getline
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h> // For bool type
#include <limits.h>  // For PATH_MAX (optional, provides a hint for buffer size)

// Define a reasonable maximum path length if PATH_MAX isn't available or suitable
#ifndef PATH_MAX
#define PATH_MAX 4096
#endif

#define GZIP_COMMAND_TEMPLATE "gzip > \"%s\""
#define MAX_GZIP_COMMAND_LEN (sizeof(GZIP_COMMAND_TEMPLATE) + PATH_MAX)

int main() {
    char *line = NULL;
    size_t len = 0;
    ssize_t read;

    char filename[PATH_MAX] = {0}; // Buffer for extracted filename
    char gzip_filename[PATH_MAX] = {0}; // Buffer for gzipped filename
    char gzip_command[MAX_GZIP_COMMAND_LEN] = {0}; // Buffer for the popen command
    FILE *outfile = NULL; // File pointer for the pipe to gzip

    const char *dumping_prefix = "-- Dumping";
    const char *insert_prefix = "INSERT INTO `"; // Note the backtick

    while ((read = getline(&line, &len, stdin)) != -1) {

        // Check for "-- Dumping" line
        if (strncmp(line, dumping_prefix, strlen(dumping_prefix)) == 0) {
            // Find the first backtick
            char *start_quote = strchr(line, '`');
            if (start_quote) {
                start_quote++; // Move past the opening backtick
                // Find the closing backtick
                char *end_quote = strchr(start_quote, '`');
                if (end_quote) {
                    size_t filename_len = end_quote - start_quote;
                    if (filename_len < sizeof(filename) - 1) { // Ensure space for null terminator
                        strncpy(filename, start_quote, filename_len);
                        filename[filename_len] = '\0'; // Null terminate

                        // Construct gzip filename and command
                        snprintf(gzip_filename, sizeof(gzip_filename), "%s.gz", filename);
                        snprintf(gzip_command, sizeof(gzip_command), GZIP_COMMAND_TEMPLATE, gzip_filename);

                        fprintf(stderr, "Processing table and writing to: %s\n", gzip_filename);

                        // Close previous pipe if open
                        if (outfile) {
                            if (pclose(outfile) == -1) {
                                perror("pclose failed");
                                // Decide if this is fatal or recoverable
                            }
                            outfile = NULL;
                        }

                        // Open new pipe to gzip
                        outfile = popen(gzip_command, "w");
                        if (!outfile) {
                            perror("popen failed");
                            fprintf(stderr, "Command: %s\n", gzip_command);
                            free(line);
                            return 1; // Exit if we can't open the output pipe
                        }
                    } else {
                        fprintf(stderr, "Error: Extracted filename too long: %.*s\n", (int)filename_len, start_quote);
                        // Handle error - maybe skip this table?
                    }
                }
            }
             continue; // Skip to next line (like AWK's 'next')
        }

        // Check for "INSERT INTO" line - only process if outfile is open
        if (outfile && strncmp(line, insert_prefix, strlen(insert_prefix)) == 0) {
            // Calculate where data values start
            // "INSERT INTO `<filename>` VALUES (" length
            // Need to find the end of " VALUES (" after the table name
            char *values_ptr = strstr(line, " VALUES (");
             if (!values_ptr) {
                 fprintf(stderr, "Warning: Could not find ' VALUES (' pattern in INSERT line: %s", line);
                 continue; // Skip malformed line
             }

            size_t start_of_data = (values_ptr - line) + strlen(" VALUES "); // Start at the opening parenthesis

            // Initialize state variables
            bool p = false; // is_within_parentheses (start *outside* the first tuple's parens)
            bool q = false; // is_within_quotes
            bool b = false; // is_preceded_by_backslash (for the *next* character)

            // Loop through characters starting from the data
            // Use 'read - 1' to potentially exclude the trailing newline read by getline
            size_t line_len = strlen(line);
            if (line[line_len - 1] == '\n') {
                line_len--; // Don't process the newline character itself
            }

            for (size_t i = start_of_data; i < line_len; i++) {
                char char_current = line[i];

                // Store the backslash state relevant *for this character*
                bool was_escaped = b;
                // Reset backslash flag for the *next* character by default
                b = false;

                // Check for an *unescaped* backslash first.
                if (char_current == '\\' && !was_escaped) {
                    b = true;    // Set flag: the *next* character is preceded by a backslash
                    continue;   // Go to the next character (effectively skipping this '\')
                }

                // Unescaped single quote toggles is_within_quotes state and prints a double quote.
                if (char_current == '\'' && !was_escaped) {
                    q = !q;     // Flip the is_within_quotes state
                    if (fputc('"', outfile) == EOF) {
                         perror("fputc '\"' failed"); goto write_error;
                    }
                    continue;   // Go to the next character
                }

                // Double quote is doubled and written to the file.
                if (char_current == '"') {
                     if (fputc('"', outfile) == EOF || fputc('"', outfile) == EOF) {
                         perror("fputc double '\"' failed"); goto write_error;
                    }
                    continue;   // Go to the next character
                }

                // Comma outside parentheses is skipped.
                if (char_current == ',' && !p) { // Check if char is comma AND is_within_parentheses is FALSE
                    continue;   // Go to the next character
                }

                // Open parenthesis when *not* already in parentheses.
                // Sets state and skips printing the parenthesis.
                if (char_current == '(' && !p) {
                    p = true;   // Set is_within_parentheses to TRUE
                    continue;   // Go to the next character
                }

                // Close parenthesis when *not* within quotes.
                // Resets state, prints a newline, and skips printing the parenthesis.
                if (char_current == ')' && !q) { // Check if char is ')' AND is_within_quotes is FALSE
                    p = false;  // Set is_within_parentheses to FALSE
                    if (fputc('\n', outfile) == EOF) {
                        perror("fputc newline failed"); goto write_error;
                    }
                    continue;   // Go to the next character
                }

                 // Discard a final semicolon if not within quotes (often marks end of INSERT)
                 if (char_current == ';' && !q) {
                     continue; // Go to the next character
                 }

                // Write the character to the file.
                // This rule executes if none of the 'continue' statements above were triggered.
                if (fputc(char_current, outfile) == EOF) {
                    perror("fputc char failed"); goto write_error;
                }
            } // End character loop
        } // End INSERT INTO block
    } // End while getline

    // Clean up: Close the last pipe if it's still open
    if (outfile) {
        if (pclose(outfile) == -1) {
            perror("pclose failed at end");
        }
        outfile = NULL;
    }

    free(line); // Free memory allocated by getline
    return 0; // Indicate success

write_error: // Label for handling write errors during character processing
    if (outfile) {
       fprintf(stderr, "Error occurred while writing to pipe for %s.\n", gzip_filename);
       // pclose still needs to be called, even after an error, to reap the child process.
       // The return value might indicate an error anyway.
       if (pclose(outfile) == -1) {
          perror("pclose failed after write error");
       }
       outfile = NULL; // Prevent further writes
       // Consider deleting the potentially corrupt gzip file here
       // remove(gzip_filename);
    }

    free(line); // Free memory allocated by getline
    return 0; // Indicate success
}
